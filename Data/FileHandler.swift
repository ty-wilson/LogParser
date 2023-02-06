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

final class FileHandler: ObservableObject {
    
    static let numberFormatter = NumberFormatter()
    static let dateToShortTextFormatter = DateFormatter()
    static let dateToLongTextFormatter = DateFormatter()
    static let dateToTextWithNoTimeFormatter = DateFormatter()
    
    private let textToShortDateFormatter: DateFormatter
    private let textToLongDateFormatter: DateFormatter
    
    private var file: File?
    public var logArray = [Log]()
    
    public var startingDate: EquatableDate
    public var parsedDates: ParsedDates
    
    @Published var status: Status = .waiting
    @Published var percentDatesLoaded: Double = 0
    @Published var percentLogsLoaded: Double = 0
    @Published var numDatesLoaded: Int = 0
    @Published var numLogsLoaded: Int = 0
    
    enum Status: String {
        case waiting
        case loading_file
        case loading_dates
        case loading_logs
        case loaded
        case reloading
        
        func toString(fileHandler: FileHandler) -> String {
            switch self {
                case .waiting:
                    return "Waiting"
                case .loading_file:
                    return "Opening file..."
                case .loading_dates:
                    return "Checking for available dates..."
                case .loading_logs, .reloading:
                    return "Parsing logs starting at \(FileHandler.dateToTextWithNoTimeFormatter.string(from: fileHandler.startingDate.d))..."
                case .loaded:
                    return "Loaded"
            }
        }
    }
    
    init() {
        print("Initializing File Handler")
        textToShortDateFormatter = DateFormatter()
        textToShortDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        textToShortDateFormatter.dateFormat = "yyyy-MM-dd"
        textToShortDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        textToLongDateFormatter = DateFormatter()
        textToLongDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        textToLongDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss,SSS"
        textToLongDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        FileHandler.dateToShortTextFormatter.locale = Locale(identifier: "en_US_POSIX")
        FileHandler.dateToShortTextFormatter.dateStyle = .long
        FileHandler.dateToShortTextFormatter.timeStyle = .short
        FileHandler.dateToShortTextFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        FileHandler.dateToTextWithNoTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        FileHandler.dateToTextWithNoTimeFormatter.dateStyle = .short
        FileHandler.dateToTextWithNoTimeFormatter.timeZone = .none
        FileHandler.dateToTextWithNoTimeFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        FileHandler.dateToLongTextFormatter.locale = Locale(identifier: "en_US_POSIX")
        FileHandler.dateToLongTextFormatter.dateStyle = .full
        FileHandler.dateToLongTextFormatter.timeStyle = .medium
        FileHandler.dateToLongTextFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        FileHandler.numberFormatter.numberStyle = .decimal
        
        parsedDates = ParsedDates()
        startingDate = convertToShortDate(Date())
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
                FileHandler.alertMessage("Failed to open file:\n\(filePath)")
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
    
    /*Get*/
    
    func getFilePath() -> String {
        return file!.getPath()
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
        
        //adjust search text
        let textToSearchFor = filter.ignoreCase ? filter.searchText.lowercased() : filter.searchText
        
        while(logArray.count > logIndex) {
            let log = logArray[logIndex]
            
            let foundText = searchLogs(log, textToSearchFor, filter)
            
            //add log if conditions are met
            if(foundText && (
                filter.showErrors && log.title == .ERROR ||
                filter.showWarns && log.title == .WARN ||
                log.title == Log.Title.FATAL)) {
                foundIndexArray.append(logIndex)
            }
            
            logIndex += 1
        }
        
        return foundIndexArray
    }
    
    private func searchLogs(_ log: Log, _ textToSearchFor: String, _ filter: Filter) -> Bool {
        var foundText = true; //set to true so everything is returned on a blank search

        if(textToSearchFor != ""){
            
            foundText = false
            
            foundText = searchProcess(log, textToSearchFor, filter)
            if(!foundText) { foundText = searchTextOrTrace(log, textToSearchFor, filter) }
            if(!foundText) { foundText = searchDateRange(log, textToSearchFor, filter) }
            if(!foundText) { foundText = searchAllDates(log, textToSearchFor, filter)}
            if(!foundText) { foundText = searchThread(log, textToSearchFor, filter) }
        }
        
        return foundText
    }
    
    private func searchProcess(_ log: Log, _ textToSearchFor: String, _ filter: Filter) -> Bool {
        var foundText = false
        let processText = filter.ignoreCase ? log.process.lowercased() : log.process
        
        if(processText.contains(textToSearchFor)) {
            foundText = true
        }
        
        return foundText
    }
    
    private func searchTextOrTrace(_ log: Log, _ textToSearchFor: String, _ filter: Filter) -> Bool {
        var foundText = false
        
        //search traces
        if(filter.includeTrace){
            for trace in log.traceAtLine.values {
                let traceText = filter.ignoreCase ? trace.lowercased() : trace
                
                if(traceText.contains(textToSearchFor)) {
                    foundText = true
                }
           }
        }
        //only search text
        else {
            let traceText = filter.ignoreCase ? log.text.lowercased() : log.text
            
            if(traceText.contains(textToSearchFor)) {
                foundText = true
            }
        }
        
        return foundText
    }
    
    private func searchDateRange(_ log: Log, _ textToSearchFor: String, _ filter: Filter) -> Bool {
        var foundText = false
        let dateRangeTextRaw = FileHandler.dateRangeText(log)
        let dateRangeText = filter.ignoreCase ? dateRangeTextRaw.lowercased() : dateRangeTextRaw
        
        if(dateRangeText.contains(textToSearchFor)) {
            foundText = true
        }
        
        return foundText
    }
    
    private func searchAllDates(_ log: Log, _ textToSearchFor: String, _ filter: Filter) -> Bool {
        var foundText = false
        
        if(filter.includeTrace) {
            for date in log.dateAtLine.values {
                if date != nil {
                    let dateTextRaw = FileHandler.dateToLongTextFormatter.string(from: date!)
                    let dateText = filter.ignoreCase ? dateTextRaw.lowercased() : dateTextRaw
                    if(dateText.contains(textToSearchFor)) {
                        foundText = true
                    }
                }
            }
        }
        
        return foundText
    }
    
    private func searchThread(_ log: Log, _ textToSearchFor: String, _ filter: Filter) -> Bool {
        var foundText = false
        
        if(filter.includeTrace) {
            for thread in log.threadAtLine.values {
                let threadText = filter.ignoreCase ? thread.lowercased() : thread
                if(threadText.contains(textToSearchFor)) {
                    foundText = true
                }
            }
        }
        
        return foundText
    }
    
    /*Static*/
    
    static func stringToTitle(_ string: String) -> Log.Title {
        switch string {
            case "ERROR": return .ERROR
            case "INFO": return .INFO
            case "WARN": return .WARN
            case "FATAL": return .FATAL
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
    
    static func dateRangeText(_ log: Log) -> String {
        if(log.lineNum.count > 1) {
            return "\(FileHandler.dateToShortTextFormatter.string(from: log.dateAtLine[log.lineNum[0]]!!)) - " +
                "\(FileHandler.dateToShortTextFormatter.string(from: log.dateAtLine[log.lineNum[log.lineNum.count - 1]]!!))"
        } else {
            return "\(FileHandler.dateToShortTextFormatter.string(from: log.dateAtLine[log.lineNum[0]]!!))"
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
                //Update status every 99 lines
                if (fileIndex % 99 == 0) {
                    UI {
                        self.percentDatesLoaded = 100 * (Double(fileIndex) / Double(self.file!.lines.count))
                        self.numDatesLoaded = self.parsedDates.count()
                    }//End UI
                }
                
                let seperator = self.file!.lines[fileIndex].firstIndex(of: " ")
                
                //Find date
                if (seperator != nil)
                {
                    //let dateText = self.file!.lines[fileIndex][...seperator!].dropLast()
                    let dateText = self.file!.lines[fileIndex].prefix(10)
                    let date = self.textToShortDateFormatter.date(from: String(dateText))
                    
                    //If date is found...
                    if (date != nil)
                    {
                        let shortDate = EquatableDate(d: date!)
                        //Add date if new
                        if(!self.parsedDates.contains(shortDate)) {
                            self.parsedDates.add(shortDate, occurances: 1, firstIndex: fileIndex)
                        }
                        //Else add occurance
                        else {
                            self.parsedDates.addOccurance(shortDate)
                        }
                    }
                }
            }
            //End Parsing
            
            //Update status
            UI {
                self.percentDatesLoaded = 100
                self.numDatesLoaded = self.parsedDates.count()
                print("Load dates result, lines: \(self.file!.lines.count), dates: \(self.parsedDates.count())")
            }//End UI
            
            //If at least one date is found, load logs
            if(self.parsedDates.count() > 0) {
                //Start parsing logs at the most recent date
                self.startingDate = self.parsedDates.getLast()
                self.loadLogs(true)
            } else {
                UI {
                    self.status = .waiting
                }//End UI
                FileHandler.alertMessage("Unrecognized file contents:\n\(self.file!.getPath())")
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
            var discarded = 0
            var lastInsertedLogIndex: Int = 0
            var lastInsertedFileIndex: Int = 0
            //let startIndex = self.parsedDates.dateToOccurancesAndIndex[self.startingDate]!.firstIndex
            let startIndex = self.parsedDates.getClosestIndexToDate(self.startingDate)
            //print("Starting at \(self.startingDate). index: \(startIndex)")
            
            //Parsing file line by line
            for fileIndex in startIndex...self.file!.lines.count - 1{
                
                //Update status every 99 lines
                if(fileIndex % 99 == 0) {
                    UI {
                        self.percentLogsLoaded = 100 * (Double(fileIndex - startIndex) / Double(self.file!.lines.count - startIndex))
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
                            
                            //skip Info and Debug
                            if(titleChunk == "INFO" || titleChunk == "DEBUG") {
                                discarded += 1
                                continue
                            }
                            
                            //check thread and process
                            titleSeperator = self.file!.lines[fileIndex].index(after: titleSeperator!)
                            let threadSeperator1 = self.file!.lines[fileIndex][titleSeperator!...].firstIndex(of: "[")
                            var threadSeperator2 = self.file!.lines[fileIndex][threadSeperator1!...].firstIndex(of: "]")
                            
                            if(threadSeperator1 != nil && threadSeperator2 != nil) {
                                let threadChunk = self.file!.lines[fileIndex][threadSeperator1!...threadSeperator2!]
                                    .dropFirst().dropLast()
                                    .trimmingCharacters(in: .whitespaces)
                                
                                threadSeperator2 = self.file!.lines[fileIndex].index(after: threadSeperator2!)
                                let processSeperator1 = self.file!.lines[fileIndex][threadSeperator2!...].firstIndex(of: "[")
                                let processSeperator2 = self.file!.lines[fileIndex][processSeperator1!...].firstIndex(of: "]")
                                
                                if(processSeperator1 != nil && processSeperator2 != nil) {
                                    let processChunk = self.file!.lines[fileIndex][processSeperator1!...processSeperator2!]
                                        .dropFirst().dropLast()
                                        .trimmingCharacters(in: .whitespaces)
                                    
                                    let textChunk = self.file!.lines[fileIndex][processSeperator2!...]
                                        .dropFirst(3).trimmingCharacters(in: .whitespacesAndNewlines)
                                    
                                    //search logs for the text of the new log and add it
                                    var wasFound = false
                                    if (newLogArray.count != 0) {
                                        for logIndex in 0...newLogArray.count - 1 {
                                            
                                            //Remove numbers from text before comparing text process and title
                                            if (newLogArray[logIndex].text.components(separatedBy: CharacterSet.decimalDigits).joined() ==
                                                textChunk.components(separatedBy: CharacterSet.decimalDigits).joined() &&
                                                newLogArray[logIndex].process == processChunk &&
                                                newLogArray[logIndex].title.rawValue == titleChunk) {
                                                
                                                wasFound = true
                                                lastInsertedLogIndex = logIndex
                                                lastInsertedFileIndex = fileIndex
                                                
                                                //Add data to found log
                                                
                                                //Add line number
                                                newLogArray[logIndex].lineNum.append(fileIndex)
                                                //Add date at line
                                                newLogArray[logIndex].dateAtLine.updateValue(date, forKey: fileIndex)
                                                //Add thread at line
                                                newLogArray[logIndex].threadAtLine.updateValue(threadChunk, forKey: fileIndex)
                                                //Start trace at line
                                                newLogArray[logIndex].traceAtLine.updateValue(textChunk, forKey: fileIndex)
                                                continue
                                                                                                    
                                                //data check
                                                //if(log[logIndex].process != lineChunks[3]) {print("Process mismatch from line \(fileIndex) : \(lineChunks[3]) vs \(log[logIndex].process)")}
                                            }
                                        }
                                    }
                                        
                                    if(!wasFound) {
                                        let newLogRecord = Log(lineNum: [fileIndex],
                                                         dateAtLine: [fileIndex : date],
                                                         title: FileHandler.stringToTitle(titleChunk),
                                                         threadAtLine: [fileIndex : threadChunk],
                                                         process: processChunk,
                                                         text: textChunk,
                                                         traceAtLine: [fileIndex : textChunk],
                                                         showDetails: false)
                                        
                                        lastInsertedLogIndex = newLogArray.count
                                        lastInsertedFileIndex = fileIndex
                                        //Add new log data
                                        newLogArray.append(newLogRecord)
                                        continue
                                    }
                                }
                            }
                        }
                    }
                }
                
                //by default append to previous log's trace
                if(newLogArray.count != 0 && lastInsertedFileIndex == fileIndex - 1) {
                    newLogArray[lastInsertedLogIndex].traceAtLine[newLogArray[lastInsertedLogIndex].lineNum.last!]?.append("\n\(self.file!.lines[fileIndex])")
                    lastInsertedFileIndex += 1
                }
            }
            //End Parsing
            
            //Restart loading at an earlier date, if no logs were found
            if(untilFound && newLogArray.count == 0) {
                self.startingDate = EquatableDate(d: self.startingDate.d.advanced(by: TimeInterval(-1 * SECONDS_PER_DAY)))
                self.loadLogs(true)
            }
            else {
                UI {
                    self.status = .loaded
                    print("Load logs result, lines: \(self.file!.lines.count - startIndex), logs: \(newLogArray.count), discarded: \(discarded)")
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

struct EquatableDate: Equatable, Hashable, Comparable {
    static func < (lhs: EquatableDate, rhs: EquatableDate) -> Bool {
        return lhs.d.compare(rhs.d) != .orderedDescending
    }
    
    let d: Date
}
