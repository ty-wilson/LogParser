//
//  Data.swift
//  LogParser
//
//  Created by Tyler Wilson on 3/9/20.
//  Copyright © 2020 Tyler Wilson. All rights reserved.
//

import Foundation
import NotificationCenter
import AppKit

/*Structs*/

struct Log: Hashable, Identifiable {
    var id: Int {
        return dateAtLine.keys.first!
    }
    
    enum Title: String {
        case ERROR
        case WARN
        case INFO
        case MISSING
    }
    
    func getFirstDate() -> Date? {
        return dateAtLine[dateAtLine.keys.first!]!
    }
    
    var lineNum: [Int]
    var dateAtLine: Dictionary<Int, Date?>
    let title: Title
    var threadAtLine: Dictionary<Int, String>
    let process: String
    var text: String
    //var otherText: String = ""
    var traceAtLine: Dictionary<Int, String>
}

//Determines what logs to return
struct Filter {
    var showErrors: Bool
    var showWarns: Bool
    var startingDate: Date
}

//Startup data
struct LoadingDatesData {
    public var shortDatesList: [Date] //expects only short dates from convertToShortDate or shortDateFormatter
    public var occurancesList: [Int]
    public var firstIndexList: [Int]
    
    func occurancesAt(_ rawDate: Date) -> Int {
        let shortDate = convertToShortDate(rawDate)
        if(shortDatesList.firstIndex(of: shortDate) != nil) {
            return occurancesList[shortDatesList.firstIndex(of: shortDate)!]
        }
        else {
            return 0
        }
    }
    
    func occurancesAfterAndIncluding(_ rawDate: Date) -> Int {
        let shortDate = convertToShortDate(rawDate)
        var total = 0
        
        //Check if dates in the datesData are after the date and add the occurances from that date to the total
        if(shortDatesList.firstIndex(of: shortDate) != nil) {
            for datesIndex in 0...shortDatesList.count - 1 {
                if (shortDatesList[datesIndex].compare(shortDate) != .orderedAscending) {
                    total += occurancesList[datesIndex]
                }
            }
        }
        
        return total
    }
    
    func convertToShortDate(_ date: Date) -> Date {
        let extraTime = Int(date.timeIntervalSince1970) % SECONDS_PER_DAY
        let newDate = Date(timeIntervalSince1970: TimeInterval(Int(date.timeIntervalSince1970) - extraTime))
        return newDate
    }
}

/*Data Class*/

final class Data: ObservableObject {
    
    static let numberFormatter = NumberFormatter()
    static let dateFormatter = DateFormatter()
    
    private let shortDateFormatter: DateFormatter
    private let longDateFormatter: DateFormatter
    
    private var file: File?
    private var logArray: [Log]?
    
    public var loadingDatesData: LoadingDatesData
    
    @Published var status: Status = .waiting
    @Published var message: String?
    
    enum Status: String {
        case waiting
        case loading_file
        case loading_dates
        case loading_logs
        case loaded
        case reloading
        
        func toString() -> String {
            switch self {
                case .waiting:
                    return "Waiting"
                case .loading_file:
                    return "Opening file..."
                case .loading_dates:
                    return "Checking for available dates..."
                case .loading_logs:
                    return "Parsing logs..."
                case .loaded:
                    return "Loaded"
                case .reloading:
                    return "Parsing logs..."
            }
        }
    }
    
    init() {
        shortDateFormatter = DateFormatter()
        shortDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        shortDateFormatter.dateFormat = "yyyy-MM-dd"
        shortDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        longDateFormatter = DateFormatter()
        longDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        longDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss,SSS"
        longDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        Data.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        Data.dateFormatter.dateStyle = .long
        Data.dateFormatter.timeStyle = .short
        
        Data.numberFormatter.numberStyle = .decimal
        
        loadingDatesData = LoadingDatesData(shortDatesList: [Date](), occurancesList: [Int](), firstIndexList: [Int]())
    }
    
    func loadFile(filePath: String) {
        BG {
            print("Begin loading file in BG")
            UI {
                self.status = .loading_file
            }
            
            self.file = File(path: filePath)
            
            //Fail to open file
            if(self.file == nil) {
                UI {
                    self.status = .waiting
                }
                Data.alertMessage("Failed to open file:\n\(filePath)")
                return
            }
            
            self.loadDates()
        }
    }
    
    /*Get*/
    
    func getFirstDate() -> Date? {
        return loadingDatesData.shortDatesList[0]
    }
    
    func getNumFilteredLogs(filter: Filter) -> Int {
        var num = 0
        
        if(logArray != nil) {
            for log in logArray! {
                if(((log.title == .ERROR) && filter.showErrors) ||
                    ((log.title == .WARN) && filter.showWarns)) {
                    num += 1
                }
            }
        }
        
        return num
    }
    
    func getLogs(filter: Filter) -> [Log]? {
        var foundLogArray = [Log]()
        let logArray = self.logArray ?? [Log]()
        var logIndex = 0
        
        //Load page up to page size, starting at logIndex, stop at end of logArray
        while(logArray.count > logIndex) {
            if(filter.showErrors && logArray[logIndex].title == .ERROR) {
                foundLogArray.append(logArray[logIndex])
            } else if(filter.showWarns && logArray[logIndex].title == .WARN) {
                foundLogArray.append(logArray[logIndex])
            }
            
            logIndex += 1
        }
        
        return foundLogArray
    }
    
    /*Static*/
    
    static func stringToTitle(_ string: String) -> Log.Title {
        switch string {
            case "ERROR": return .ERROR
            case "INFO": return .INFO
            case "WARN": return .WARN
            default: print("Could not find title \(string)"); return .MISSING
        }
    }
    
    static func getFormattedNumber(_ num: Int) -> String {
        return self.numberFormatter.string(from: NSNumber(value: num)) ?? "invalid number"
    }
    
    static func alertMessage(_ text: String) {
        UIS {
            let alert = NSAlert()
            alert.messageText = text
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    /*Parsing*/
    
    //Called after loadFile, requires a file
    private func loadDates() {
        //Enter background thread
        BG {

            UI {
                self.status = .loading_dates
            }
            
            //Parsing
            for fileIndex in 0...self.file!.lines.count - 1{
                
                //Update status every 99? lines
                if(fileIndex % 99 == 0) {
                    UI {
                        self.message = "line: \(Data.getFormattedNumber(fileIndex))/\(Data.getFormattedNumber(self.file!.lines.count)) | unique dates: \(Data.getFormattedNumber(self.loadingDatesData.shortDatesList.count))"
                    }//End UI
                }
                
                let seperator = self.file!.lines[fileIndex].firstIndex(of: " ")
                
                //Find date
                if(seperator != nil)
                {
                    let dateText = self.file!.lines[fileIndex][...seperator!].dropLast()
                    let date = self.shortDateFormatter.date(from: String(dateText))
                    
                    if(date != nil)
                    {
                        //Add date if new
                        if(!self.loadingDatesData.shortDatesList.contains(date!)) {
                            //print(self.status.rawValue + ": adding " + date!.description)
                            self.loadingDatesData.shortDatesList.append(date!)
                            self.loadingDatesData.occurancesList.append(1)
                            self.loadingDatesData.firstIndexList.append(fileIndex)
                        }
                        //Add occurance
                        else {
                            self.loadingDatesData.occurancesList[self.loadingDatesData.shortDatesList.firstIndex(of: date!)!] += 1
                        }
                    }
                }
            }
            //End Parsing
            
            UI {
                self.message = "line: \(Data.getFormattedNumber(self.file!.lines.count))/\(Data.getFormattedNumber(self.file!.lines.count))" +
                " | unique dates: \(Data.getFormattedNumber(self.loadingDatesData.shortDatesList.count))"
                
                print("Load dates result, lines: \(self.file!.lines.count), dates: \(self.loadingDatesData.shortDatesList.count)")
            }//End UI
            
            //Load logs next
            if(self.loadingDatesData.shortDatesList.count > 0) {
                self.loadLogs(filter: Filter(showErrors: true, showWarns: true,
                            startingDate: self.loadingDatesData.shortDatesList[self.loadingDatesData.shortDatesList.count - 1]))
            } else {
                UI {
                    self.status = .waiting
                }
                Data.alertMessage("Unrecognized file contents:\n\(self.file!.getPath())")
                return
            }
            
            print("End of BG task for loadDates()")
            
        }//End BG
        print("Called loadDates()")
    }
    
    func loadLogs(filter: Filter) {
        
        var newLogArray = [Log]()
        
        //Enter background thread
        BG {
            UI {
                if(self.status == .loaded) {
                    self.status = .reloading
                } else {
                    self.status = .loading_logs
                }
            }
            
            //Data
            var appended = 0
            var discarded = 0
            var lastLogIndex: Int = 0
            let startIndex = self.loadingDatesData.firstIndexList[self.loadingDatesData.shortDatesList.firstIndex(of: filter.startingDate)!]
            print("Starting at index: \(startIndex)")
            
            //Parsing
            for fileIndex in startIndex...self.file!.lines.count - 1{
                
                //Update status every 99 lines
                if(fileIndex % 99 == 0) {
                    UI {
                        self.message = "line: \(Data.getFormattedNumber(fileIndex - startIndex))/\(Data.getFormattedNumber(self.file!.lines.count - startIndex)) | unique logs: \(Data.getFormattedNumber(newLogArray.count))"
                    }//End UI
                }
                
                //Split into info and description
                let splitLine = self.file!.lines[fileIndex].components(separatedBy: " - ")
                
                //Break out info chunks from first half of split
                var lineChunks = splitLine[0].components(separatedBy: ["[", "]"])
                
                //Remove whitespace and empty chunks
                for chunksIndex in 0...lineChunks.count - 1 {
                    lineChunks[chunksIndex] = lineChunks[chunksIndex].trimmingCharacters(in: .whitespaces)
                }
                lineChunks = lineChunks.filter({ $0 != ""})
                
                //Check for discardable lines:
                //Discard if we did not find 4 chunks at start of line
                //Discard if not Error or Warn
                if(lineChunks.count == 4 && !(lineChunks[1] == "ERROR" || lineChunks[1] == "WARN")) {
                    //print("Discarding line \(fileIndex):\n\(file.lines[fileIndex])")
                    discarded += 1
                    continue
                }
                
                //If not formattable or discardable, append to last the most recently found log's current trace
                if(lineChunks.count != 4) {
                    //print("Appending to \(lastLogIndex)")
                    if(newLogArray.count != 0) {
                        newLogArray[lastLogIndex].traceAtLine[newLogArray[lastLogIndex].lineNum.last!]?.append("\n\(self.file!.lines[fileIndex])")
                        appended += 1
                    }
                    continue
                }
                
                //search logs for the text of the new log and add it
                var wasFound = false
                if (newLogArray.count != 0) {
                    for logIndex in 0...newLogArray.count - 1 {
                        
                        //Remove numbers from text before comparing
                        if (newLogArray[logIndex].text.components(separatedBy: CharacterSet.decimalDigits).joined() == splitLine[1].components(separatedBy: CharacterSet.decimalDigits).joined() &&
                            newLogArray[logIndex].process == lineChunks[3]) {
                            wasFound = true
                            lastLogIndex = logIndex
                            
                            //Add data to found log
                            
                            //Add line number
                            newLogArray[logIndex].lineNum.append(fileIndex)
                            //Add date at line
                            let date = self.longDateFormatter.date(from: String(lineChunks[0]))
                            if(date != nil) {
                                newLogArray[logIndex].dateAtLine.updateValue(date, forKey: fileIndex)
                            } else {
                                print("Discarding date: " + lineChunks[0])
                            }
                            //Add thread at line
                            newLogArray[logIndex].threadAtLine.updateValue(lineChunks[2], forKey: fileIndex)
                            //Start trace at line
                            newLogArray[logIndex].traceAtLine.updateValue(splitLine[1], forKey: fileIndex)
                            
                            continue
                                                                                
                            //data check
                            //if(log[logIndex].title != stringToTitle(lineChunks[1])){print("Title mismatch from line \(fileIndex): \(log[logIndex].title) vs \(lineChunks[1])")}
                            //if(log[logIndex].process != lineChunks[3]) {print("Process mismatch from line \(fileIndex) : \(lineChunks[3]) vs \(log[logIndex].process)")}
                        }
                    }
                }
                    
                if(!wasFound) {
                    let newLogRecord = Log(lineNum: [fileIndex],
                                     dateAtLine: [fileIndex : self.longDateFormatter.date(from: lineChunks[0])],
                                     title: Data.stringToTitle(lineChunks[1]),
                                     threadAtLine: [fileIndex : lineChunks[2]],
                                     process: lineChunks[3],
                                     text: splitLine[1],
                                     traceAtLine: [fileIndex : splitLine[1]])
                    
                    lastLogIndex = newLogArray.count
                    //Add new log data
                    newLogArray.append(newLogRecord)
                }
            }
            //End Parsing
            
            UI {
                self.message = "line: \(Data.getFormattedNumber(self.file!.lines.count - startIndex))/\(Data.getFormattedNumber(self.file!.lines.count - startIndex))" +
                " | unique logs: \(Data.getFormattedNumber(newLogArray.count))"
                
                print("Load logs result, lines: \(self.file!.lines.count - startIndex), logs: \(newLogArray.count), discarded: \(discarded), appended: \(appended)")
                
                self.status = .loaded
            }//End UI
            
            //Save log
            self.logArray = newLogArray
            print("End of BG task for loadLogs()")
            
        } //End BG
        print("Called loadLogs()")
    }
}

func BG(_ block: @escaping ()->Void) {
    DispatchQueue.global(qos: .default).async(execute: block)
}

func UI(_ block: @escaping ()->Void) {
    DispatchQueue.main.async(execute: block)
}

func UIS(_ block: @escaping ()->Void) {
    DispatchQueue.main.sync(execute: block)
}

extension Int: Identifiable{
    public var id: Int {
        return self
    }
}
