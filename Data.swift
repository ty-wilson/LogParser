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

let SECONDS_PER_DAY = 86400

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
    
    mutating func toggleDetails() {
        showDetails = !showDetails
    }
    
    var lineNum: [Int]
    var dateAtLine: Dictionary<Int, Date?>
    let title: Title
    var threadAtLine: Dictionary<Int, String>
    let process: String
    let text: String
    var traceAtLine: Dictionary<Int, String>
    var showDetails: Bool
}

//Determines what logs to return
struct Filter {
    var showErrors: Bool
    var showWarns: Bool
    var searchText: String
    var includeTrace: Bool
    var ignoreCase: Bool
}

struct ShortDate: Equatable {
    let d: Date
}

//Startup data
struct LoadingDatesData {
    public var shortDatesList: [ShortDate] //expects only short dates from convertToShortDate or textToShortDateFormatter
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
                if (shortDatesList[datesIndex].d.compare(shortDate.d) != .orderedAscending) {
                    total += occurancesList[datesIndex]
                }
            }
        }
        
        return total
    }
    
    func convertToShortDate(_ date: Date) -> ShortDate {
        let extraTime = Int(date.timeIntervalSince1970) % SECONDS_PER_DAY
        let newDate = Date(timeIntervalSince1970: TimeInterval(Int(date.timeIntervalSince1970) - extraTime))
        return ShortDate(d: newDate)
    }
}

/*Data Class*/

final class Data: ObservableObject {
    
    static let numberFormatter = NumberFormatter()
    static let dateToShortTextFormatter = DateFormatter()
    static let dateToLongTextFormatter = DateFormatter()
    static let dateToTextWithNoTimeFormatter = DateFormatter()
    
    private let textToShortDateFormatter: DateFormatter
    private let textToLongDateFormatter: DateFormatter
    
    private var file: File?
    public var logArray = [Log]()
    
    public var startingDate: ShortDate
    public var loadingDatesData: LoadingDatesData
    
    @Published var status: Status = .waiting
    @Published var percDatesLoaded: Double = 0
    @Published var percLogsLoaded: Double = 0
    @Published var numDatesLoaded: Int = 0
    @Published var numLogsLoaded: Int = 0
    
    enum Status: String {
        case waiting
        case loading_file
        case loading_dates
        case loading_logs
        case loaded
        case reloading
        
        func toString(data: Data) -> String {
            switch self {
                case .waiting:
                    return "Waiting"
                case .loading_file:
                    return "Opening file..."
                case .loading_dates:
                    return "Checking for available dates..."
                case .loading_logs, .reloading:
                    return "Parsing logs starting at \(Data.dateToTextWithNoTimeFormatter.string(from: data.startingDate.d))..."
                case .loaded:
                    return "Loaded"
            }
        }
    }
    
    init() {
        
        print("Initializing Data")
        textToShortDateFormatter = DateFormatter()
        textToShortDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        textToShortDateFormatter.dateFormat = "yyyy-MM-dd"
        textToShortDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        textToLongDateFormatter = DateFormatter()
        textToLongDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        textToLongDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss,SSS"
        textToLongDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        Data.dateToShortTextFormatter.locale = Locale(identifier: "en_US_POSIX")
        Data.dateToShortTextFormatter.dateStyle = .long
        Data.dateToShortTextFormatter.timeStyle = .short
        Data.dateToShortTextFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        Data.dateToTextWithNoTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        Data.dateToTextWithNoTimeFormatter.dateStyle = .short
        Data.dateToTextWithNoTimeFormatter.timeZone = .none
        Data.dateToTextWithNoTimeFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        Data.dateToLongTextFormatter.locale = Locale(identifier: "en_US_POSIX")
        Data.dateToLongTextFormatter.dateStyle = .full
        Data.dateToLongTextFormatter.timeStyle = .medium
        Data.dateToLongTextFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        Data.numberFormatter.numberStyle = .decimal
        
        loadingDatesData = LoadingDatesData(shortDatesList: [ShortDate](), occurancesList: [Int](), firstIndexList: [Int]())
        startingDate = loadingDatesData.convertToShortDate(Date())
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
    
    func toggleShowDetails(_ logToChange: Log) {
        for index in 0...logArray.count - 1 {
            if(logArray[index].text == logToChange.text && logArray[index].title == logToChange.title) {
                logArray[index].toggleDetails()
            }
        }
    }
    
    func getFilePath() -> String {
        return file!.getPath()
    }
    
    /*Get*/
    
    func getFirstDate() -> Date? {
        return loadingDatesData.shortDatesList[0].d
    }
    
    func getNumFilteredLogs(filter: Filter) -> Int {
        return filterLogs(filter: filter).count
    }
    
    func getFilteredLogs(filter: Filter) -> [Log] {
        var foundLogArray = [Log]()
        for index in filterLogs(filter: filter) {
            foundLogArray.append(logArray[index])
        }
        return foundLogArray
    }
    
    func filterLogs(filter: Filter) -> [Int] {
        var foundIndexArray = [Int]()
        var logIndex = 0
        
        while(logArray.count > logIndex) {
            
            //Compare with filter
            
            //search traces
            if(filter.includeTrace && filter.searchText != ""){
                var found = false
                
                var textToSearchFor: String
                if(filter.ignoreCase) {
                    textToSearchFor = filter.searchText.lowercased()
                } else {
                    textToSearchFor = filter.searchText
                }
                
                for trace in logArray[logIndex].traceAtLine.values {
                    
                    var textToSearch: String
                    if(filter.ignoreCase) {
                        textToSearch = trace.lowercased()
                    } else {
                        textToSearch = trace
                    }
                    
                   if(textToSearch.contains(textToSearchFor)) {
                       found = true
                   }
               }
                if(!found) {
                    logIndex += 1
                    continue
                }
            //Only search text
            } else if(filter.searchText != ""){
                
                var textToSearchFor: String
                if(filter.ignoreCase) {
                    textToSearchFor = filter.searchText.lowercased()
                } else {
                    textToSearchFor = filter.searchText
                }
                
                var textToSearch: String
                if(filter.ignoreCase) {
                    textToSearch = logArray[logIndex].text.lowercased()
                } else {
                    textToSearch = logArray[logIndex].text
                }
                
                if(!textToSearch.contains(textToSearchFor)) {
                    logIndex += 1
                    continue
                }
            }
            
            //add log if conditions were met
            if(filter.showErrors && logArray[logIndex].title == .ERROR ||
                filter.showWarns && logArray[logIndex].title == .WARN) {
                foundIndexArray.append(logIndex)
            }
            
            logIndex += 1
        }
        
        return foundIndexArray
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
            for fileIndex in 0...self.file!.lines.count - 1 {
                
                //Update status every 99? lines
                if (fileIndex % 99 == 0) {
                    UI {
                        self.percDatesLoaded = 100 * (Double(fileIndex) / Double(self.file!.lines.count))
                        self.numDatesLoaded = self.loadingDatesData.shortDatesList.count
                        
                    }//End UI
                }
                
                let seperator = self.file!.lines[fileIndex].firstIndex(of: " ")
                
                //Find date
                if (seperator != nil)
                {
                    let dateText = self.file!.lines[fileIndex][...seperator!].dropLast()
                    let date = self.textToShortDateFormatter.date(from: String(dateText))
                    
                    if (date != nil)
                    {
                        let shortDate = ShortDate(d: date!)
                        //Add date if new
                        if(!self.loadingDatesData.shortDatesList.contains(shortDate)) {
                            //print(self.status.rawValue + ": adding " + date!.description)
                            self.loadingDatesData.shortDatesList.append(shortDate)
                            self.loadingDatesData.occurancesList.append(1)
                            self.loadingDatesData.firstIndexList.append(fileIndex)
                        }
                        //Add occurance
                        else {
                            self.loadingDatesData.occurancesList[self.loadingDatesData.shortDatesList.firstIndex(of: shortDate)!] += 1
                        }
                    }
                }
            }
            //End Parsing
            
            UI {
                self.percDatesLoaded = 100
                self.numDatesLoaded = self.loadingDatesData.shortDatesList.count
                
                print("Load dates result, lines: \(self.file!.lines.count), dates: \(self.loadingDatesData.shortDatesList.count)")
            }//End UI
            
            //Load logs next
            if(self.loadingDatesData.shortDatesList.count > 0) {
                self.startingDate = self.loadingDatesData.shortDatesList[self.loadingDatesData.shortDatesList.count - 1]
                self.loadLogs(true)
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
    
    func loadLogs(_ untilFound: Bool = false) {
        
        //Enter background thread
        BG {
            var newLogArray = [Log]()
            
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
            let startIndex = self.loadingDatesData.firstIndexList[self.loadingDatesData.shortDatesList.firstIndex(of: self.startingDate)!]
            //print("Starting at \(self.startingDate). index: \(startIndex)")
            
            //Parsing
            for fileIndex in startIndex...self.file!.lines.count - 1{
                
                //Update status every 99 lines
                if(fileIndex % 99 == 0) {
                    UI {
                        self.percLogsLoaded = 100 * (Double(fileIndex - startIndex) / Double(self.file!.lines.count - startIndex))
                        self.numLogsLoaded = newLogArray.count
                    }//End UI
                }
                
                //Check date
                let dateSeperator = self.file!.lines[fileIndex].firstIndex(of: "[")
                if(dateSeperator != nil && dateSeperator != self.file!.lines[fileIndex].startIndex) {
                    let dateChunk = self.file!.lines[fileIndex][...(self.file!.lines[fileIndex].index(before: dateSeperator!) )]
                    let date = self.textToLongDateFormatter.date(from: String(dateChunk))
                    
                    //If date was found, check title
                    if(date != nil) {
                        var titleSeperator = self.file!.lines[fileIndex][dateSeperator!...].firstIndex(of: "]")
                        
                        if(titleSeperator != nil) {
                            let titleChunk = self.file!.lines[fileIndex][dateSeperator!...titleSeperator!]
                                .dropFirst().dropLast()
                                .trimmingCharacters(in: .whitespaces)
                            
                            //skip Info
                            if(titleChunk == "INFO") {
                                discarded += 1
                                continue
                            }
                            
                            //if title was found, check thread and process
                            if(titleChunk == "ERROR" || titleChunk == "WARN") {
                                titleSeperator = self.file!.lines[fileIndex].index(after: titleSeperator!)
                                let threadSeperator1 = self.file!.lines[fileIndex][titleSeperator!...].firstIndex(of: "[")
                                var threadSeperator2 = self.file!.lines[fileIndex][titleSeperator!...].firstIndex(of: "]")
                                
                                if(threadSeperator1 != nil && threadSeperator2 != nil) {
                                    let threadChunk = self.file!.lines[fileIndex][threadSeperator1!...threadSeperator2!]
                                        .dropFirst().dropLast()
                                        .trimmingCharacters(in: .whitespaces)
                                    
                                    threadSeperator2 = self.file!.lines[fileIndex].index(after: threadSeperator2!)
                                    let processSeperator1 = self.file!.lines[fileIndex][threadSeperator2!...].firstIndex(of: "[")
                                    let processSeperator2 = self.file!.lines[fileIndex][threadSeperator2!...].firstIndex(of: "]")
                                    
                                    if(processSeperator1 != nil && processSeperator2 != nil) {
                                        let processChunk = self.file!.lines[fileIndex][processSeperator1!...processSeperator2!]
                                            .dropFirst().dropLast()
                                            .trimmingCharacters(in: .whitespaces)
                                        
                                        let textChunk = self.file!.lines[fileIndex][processSeperator2!...]
                                            .dropFirst(3).trimmingCharacters(in: .whitespaces)
                                        
                                        //search logs for the text of the new log and add it
                                        var wasFound = false
                                        if (newLogArray.count != 0) {
                                            for logIndex in 0...newLogArray.count - 1 {
                                                
                                                //Remove numbers from text before comparing
                                                if (newLogArray[logIndex].text.components(separatedBy: CharacterSet.decimalDigits).joined() ==
                                                    textChunk.components(separatedBy: CharacterSet.decimalDigits).joined() &&
                                                    newLogArray[logIndex].process == processChunk &&
                                                    newLogArray[logIndex].title.rawValue == titleChunk) {
                                                    
                                                    wasFound = true
                                                    lastLogIndex = logIndex
                                                    
                                                    //Add data to found log
                                                    
                                                    //Add line number
                                                    newLogArray[logIndex].lineNum.append(fileIndex)
                                                    //Add date at line
                                                    newLogArray[logIndex].dateAtLine.updateValue(date, forKey: fileIndex)
                                                    //Add thread at line
                                                    newLogArray[logIndex].threadAtLine.updateValue(threadChunk, forKey: fileIndex)
                                                    //Start trace at line
                                                    newLogArray[logIndex].traceAtLine.updateValue(textChunk, forKey: fileIndex)
                                                    
                                                    appended += 1
                                                                                                        
                                                    //data check
                                                    //if(log[logIndex].process != lineChunks[3]) {print("Process mismatch from line \(fileIndex) : \(lineChunks[3]) vs \(log[logIndex].process)")}
                                                }
                                            }
                                        }
                                            
                                        if(!wasFound) {
                                            let newLogRecord = Log(lineNum: [fileIndex],
                                                             dateAtLine: [fileIndex : date],
                                                             title: Data.stringToTitle(titleChunk),
                                                             threadAtLine: [fileIndex : threadChunk],
                                                             process: processChunk,
                                                             text: textChunk,
                                                             traceAtLine: [fileIndex : textChunk],
                                                             showDetails: false)
                                            
                                            lastLogIndex = newLogArray.count
                                            //Add new log data
                                            newLogArray.append(newLogRecord)
                                            continue
                                        } else {
                                            continue
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                //append to previous trace instead
                if(newLogArray.count != 0) {
                    newLogArray[lastLogIndex].traceAtLine[newLogArray[lastLogIndex].lineNum.last!]?.append("\n\(self.file!.lines[fileIndex])")
                    appended += 1
                }
                continue
            }
            //End Parsing
            
            //Restart loading at an earlier date, if no logs were found
            if(untilFound && newLogArray.count == 0) {
                self.startingDate = ShortDate(d: self.startingDate.d.advanced(by: TimeInterval(-1 * SECONDS_PER_DAY)))
                self.loadLogs(true)
            }
            else {
                UI {
                    self.status = .loaded
                    print("Load logs result, lines: \(self.file!.lines.count - startIndex), logs: \(newLogArray.count), discarded: \(discarded), appended: \(appended)")
                }//End UI
                
                //Save log
                self.logArray = newLogArray
            }
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
