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

final class DataHelper: ObservableObject {
    
    static let numberFormatter = NumberFormatter()
    static let dateToShortTextFormatter = DateFormatter()
    static let dateToLongTextFormatter = DateFormatter()
    static let dateToTextWithNoTimeFormatter = DateFormatter()
    
    private let textToShortDateFormatter: DateFormatter
    private let textToLongDateFormatter: DateFormatter
    
    private var file: File?
    public var logArray = [Log]()
    
    public var startingDate: DateWrapper
    public var parsedDates: ParsedDates
    
    @Published var status: Status = .waiting
    @Published var percentDatesLoaded: Double = 0
    @Published var percentLogsLoaded: Double = 0
    @Published var numDatesLoaded: Int = 0
    @Published var numLogsLoaded: Int = 0
    
    private let shortDatePattern = "\\d{4}-\\d{2}-\\d{2}"
    private let longDatePattern = "\\d{4}-\\d{2}-\\d{2}[T\\s]\\d{2}:\\d{2}:\\d{2},\\d{3}"
    
    init() {
        //print("Initializing Data Helper")
        textToShortDateFormatter = DateFormatter()
        textToShortDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        textToShortDateFormatter.dateFormat = "yyyy-MM-dd"
        textToShortDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        textToLongDateFormatter = DateFormatter()
        textToLongDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        textToLongDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss,SSS"
        textToLongDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        DataHelper.dateToShortTextFormatter.locale = Locale(identifier: "en_US_POSIX")
        DataHelper.dateToShortTextFormatter.dateStyle = .long
        DataHelper.dateToShortTextFormatter.timeStyle = .short
        DataHelper.dateToShortTextFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        DataHelper.dateToTextWithNoTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        DataHelper.dateToTextWithNoTimeFormatter.dateStyle = .short
        DataHelper.dateToTextWithNoTimeFormatter.timeZone = .none
        DataHelper.dateToTextWithNoTimeFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        DataHelper.dateToLongTextFormatter.locale = Locale(identifier: "en_US_POSIX")
        DataHelper.dateToLongTextFormatter.dateStyle = .full
        DataHelper.dateToLongTextFormatter.timeStyle = .medium
        DataHelper.dateToLongTextFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        DataHelper.numberFormatter.numberStyle = .decimal
        
        parsedDates = ParsedDates()
        startingDate = convertToShortDate(Date())
    }
    
    func loadFile(url: URL) {
        BG {
            print("Begin loading file in BG")
            UI {
                self.status = .loading_file
            }
            
            if(!url.isDirectory) {
                self.file = File(path: url.path)
            } else {
                print("Directory")
            }
                
            
            //Fail to open file
            if(self.file == nil) {
                UI {
                    self.status = .waiting
                }
                DataHelper.alertMessage("Failed to open file:\n\(url.path)")
                return
            }
            
            self.loadDates()
        }
    }
    
    /*Get*/
    
    func getFileAsText() throws -> String {
        do {
            return try String(contentsOfFile: file!.getPath());
        } catch {
            DataHelper.alertMessage("Failed to open file:\n\(file!.getPath())")
            throw error
        }
    }
    
    func getFilePath() -> String {
        return file!.getPath()
    }
    
    func getNumFilteredLogs(filter: Filter) -> Int {
        return filterLogs(filter).count
    }
    
    func getFilteredLogs(filter: Filter) -> [Log] {
        var foundLogArray = [Log]()
        for index in filterLogs(filter) {
            foundLogArray.append(logArray[index])
        }
        return foundLogArray
    }
    
    func getFilteredLines(log: Log, filter: Filter) -> [Int] {
        var foundLines = [Int]()
        
        if(filter.includeTrace) {
            foundLines = filterLines(log, filter)
        }
        else {
            foundLines = log.lineNum
        }
        
        return foundLines
    }
    
    func filterLogs(_ filter: Filter) -> [Int] {
        var foundIndexArray = [Int]()
        var logIndex = 0
        
        while(logArray.count > logIndex) {
            let log = logArray[logIndex]
            
            let foundText = searchLog(log, filter)
            
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
    
    func filterLines(_ log: Log, _ filter: Filter) -> [Int] {
        var foundIndexArray = [Int]()
        var index = 0
        
        while(log.lineNum.count > index) {
            let lineNum = log.lineNum[index]
            
            if(searchLineOfLog(log, lineNum, filter)) {
                foundIndexArray.append(lineNum)
            }
            
            index += 1
        }
        
        return foundIndexArray
    }
    
    private func searchLog(_ log: Log, _ filter: Filter) -> Bool {
        var foundText = true //set to true so everything is returned on a blank search
        //adjust search text
        let textToSearchFor = filter.ignoreCase ? filter.searchText.lowercased() : filter.searchText

        if(textToSearchFor != ""){
            foundText = false
            
            foundText = searchProcess(log.process, textToSearchFor, filter)
            if(!foundText) {
                if(filter.includeTrace) {
                    foundText = searchTraces(log.traceAtLine, textToSearchFor, filter)
                } else {
                    foundText = searchText(log.text, textToSearchFor, filter)
                }
            }
            if(!foundText) { foundText = searchDateRange(log, textToSearchFor, filter) }
            if(!foundText) { foundText = searchAllLongDates(log, textToSearchFor, filter) }
            if(!foundText) { foundText = searchThreads(log.threadAtLine, textToSearchFor, filter) }
        }
        
        return foundText
    }
    
    private func searchLineOfLog(_ log: Log, _ lineNum: Int, _ filter: Filter) -> Bool {
        var foundText = true //set to true so everything is returned on a blank search
        //adjust search text
        let textToSearchFor = filter.ignoreCase ? filter.searchText.lowercased() : filter.searchText
        
        if(textToSearchFor != ""){
            foundText = false
            
            foundText = searchLongDate(log.dateAtLine[lineNum]!!, textToSearchFor, filter)
            if(!foundText) { foundText = searchThread(log.threadAtLine[lineNum]!, textToSearchFor, filter) }
            if(!foundText) { foundText = searchTrace(log.traceAtLine[lineNum]!, textToSearchFor, filter) }
            if(!foundText) { foundText = searchDateRange(log, textToSearchFor, filter) }
            if(!foundText) { foundText = searchProcess(log.process, textToSearchFor, filter) }
        }
        
        return foundText
    }
    
    private func searchProcess(_ process: String, _ textToSearchFor: String, _ filter: Filter) -> Bool {
        var foundText = false
        
        let processText = filter.ignoreCase ? process.lowercased() : process
        
        if(processText.contains(textToSearchFor)) {
            foundText = true
        }
        
        return foundText
    }
    
    private func searchTraces(_ traceAtLine: Dictionary<Int, String>, _ textToSearchFor: String, _ filter: Filter) -> Bool {
        var foundText = false
        
        for trace in traceAtLine.values {
            let traceText = filter.ignoreCase ? trace.lowercased() : trace
            
            if(traceText.contains(textToSearchFor)) {
                foundText = true
            }
        }
        
        return foundText
    }
    
    private func searchTrace(_ trace: String, _ textToSearchFor: String, _ filter: Filter) -> Bool {
        var foundText = false
        
        let traceText = filter.ignoreCase ? trace.lowercased() : trace
        
        if(traceText.contains(textToSearchFor)) {
            foundText = true
        }
        
        return foundText
    }
    
    private func searchText(_ text: String, _ textToSearchFor: String, _ filter: Filter) -> Bool {
        var foundText = false
        
        let traceText = filter.ignoreCase ? text.lowercased() : text
        
        if(traceText.contains(textToSearchFor)) {
            foundText = true
        }
        
        return foundText
    }
    
    private func searchDateRange(_ log: Log, _ textToSearchFor: String, _ filter: Filter) -> Bool {
        var foundText = false
        let dateRangeTextRaw = DataHelper.dateRangeText(log)
        let dateRangeText = filter.ignoreCase ? dateRangeTextRaw.lowercased() : dateRangeTextRaw
        
        if(dateRangeText.contains(textToSearchFor)) {
            foundText = true
        }
        
        return foundText
    }
    
    private func searchLongDate(_ date: Date, _ textToSearchFor: String, _ filter: Filter) -> Bool {
        var foundText = false
        let dateTextRaw = DataHelper.dateToLongTextFormatter.string(from: date)
        let dateText = filter.ignoreCase ? dateTextRaw.lowercased() : dateTextRaw
        
        if(dateText.contains(textToSearchFor)) {
            foundText = true
        }
        
        return foundText
    }
    
    private func searchAllLongDates(_ log: Log, _ textToSearchFor: String, _ filter: Filter) -> Bool {
        var foundText = false
        
        if(filter.includeTrace) {
            for date in log.dateAtLine.values {
                if date != nil {
                    let dateTextRaw = DataHelper.dateToLongTextFormatter.string(from: date!)
                    let dateText = filter.ignoreCase ? dateTextRaw.lowercased() : dateTextRaw
                    if(dateText.contains(textToSearchFor)) {
                        foundText = true
                    }
                }
            }
        }
        
        return foundText
    }
    
    private func searchThreads(_ threadAtLine: Dictionary<Int, String>, _ textToSearchFor: String, _ filter: Filter) -> Bool {
        var foundText = false
        
        if(filter.includeTrace) {
            for thread in threadAtLine.values {
                let threadText = filter.ignoreCase ? thread.lowercased() : thread
                if(threadText.contains(textToSearchFor)) {
                    foundText = true
                }
            }
        }
        
        return foundText
    }
    
    private func searchThread(_ thread: String, _ textToSearchFor: String, _ filter: Filter) -> Bool {
        var foundText = false
        
        let threadText = filter.ignoreCase ? thread.lowercased() : thread
        if(threadText.contains(textToSearchFor)) {
            foundText = true
        }
        
        return foundText
    }
    
    /*Parsing*/
    
    //Called after loadFile, requires a file
    private func loadDates() {
        //Enter background thread
        BG {
            UI {
                self.status = .loading_dates
            }
            
            for fileIndex in 0...self.file!.lines.count - 1 {
                //Update status every 99 lines
                if (fileIndex % 99 == 0) {
                    self.updateDatesStatus(index: fileIndex, datesLoaded: self.parsedDates.count())
                }
                
                let dateText = self.findDate(in: self.file!.lines[fileIndex], withPattern: self.shortDatePattern)
                if (dateText != nil) {
                    let date = self.textToShortDateFormatter.date(from: dateText!)
                    if (date != nil) {
                        self.processFoundDate(date: date!, index: fileIndex)
                    }
                }
            }
            
            self.updateDatesStatus(index: self.file!.lines.count, datesLoaded: self.parsedDates.count())
            print("Load dates result, lines: \(self.file!.lines.count), dates: \(self.parsedDates.count())")
            
            //If at least one date is found, load logs
            if(self.parsedDates.count() > 0) {
                //Start parsing logs at the most recent date
                self.startingDate = self.parsedDates.getLast()
                self.loadLogs(true)
            } else {
                UI {
                    self.status = .waiting
                }//End UI
                DataHelper.alertMessage("Unrecognized file contents:\n\(self.file!.getPath())")
                return
            }
            print("End of BG task for loadDates()")
        }//End BG
        print("Called loadDates()")
    }
    
    func findDate(in text: String, withPattern pattern: String) -> String? {
        var foundDate: String? = nil
        // Create a regular expression
        if let regex = try? NSRegularExpression(pattern: pattern) {
            // Search for the first match in the line
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                // Extract the matched substring
                if let dateRange = Range(match.range, in: text) {
                    foundDate = String(text[dateRange])
                }
            } else {
                print("No date found")
            }
        }
        
        return foundDate
    }
    
    private func processFoundDate(date: Date, index: Int) {
        let shortDate = DateWrapper(d: date)
        //Add date if new
        if(!self.parsedDates.contains(shortDate)) {
            self.parsedDates.addNewDate(shortDate, firstIndex: index)
        }
        //Else add occurance
        else {
            self.parsedDates.addOccurance(shortDate)
        }
    }
    
    private func updateDatesStatus(index: Int, offset: Int = 0, datesLoaded: Int) {
        UI {
            self.percentDatesLoaded = 100 * (Double(index - offset) / Double(self.file!.lines.count - offset))
            self.numDatesLoaded = datesLoaded
        }//End UI
    }
    
    func loadLogs(_ untilFound: Bool = false) {
        UI {
            if(self.status == .loaded) {
                self.status = .reloading
            } else {
                self.status = .loading_logs
            }
        }
        
        //Enter background thread
        BG {
            let newLogArray = self.parseLogs()
            
            //Restart loading at an earlier date, if no logs were found
            //this should not loop infinitely since loadDates ensures one date exists
            if(untilFound && newLogArray.count == 0) {
                self.startingDate = DateWrapper(d: self.startingDate.d.advanced(by: TimeInterval(-1 * SECONDS_PER_DAY)))
                self.loadLogs(true)
            }
            else {
                self.logArray = newLogArray
                UI {
                    self.status = .loaded
                }
            }
            print("End of BG task for loadLogs()")
        } //End BG
        print("Called loadLogs()")
    }
    
    private func parseLogs() -> [Log] {
        let startIndex = self.parsedDates.getClosestIndexToDate(self.startingDate)
        var newLogArray = [Log]()
        var discarded = 0
        var lastInsertedLogIndex: Int = 0
        var lastInsertedFileIndex: Int = 0
        let logShell = LogShell()
        
        for fileIndex in startIndex...self.file!.lines.count - 1 {
            //Update status every 99 lines
            if(fileIndex % 99 == 0) {
                UI {
                    self.percentLogsLoaded = 100 * (Double(fileIndex - startIndex) / Double(self.file!.lines.count - startIndex))
                    self.numLogsLoaded = newLogArray.count
                }//End UI
            }
            
            //date
            let dateText = self.findDate(in: self.file!.lines[fileIndex], withPattern: self.longDatePattern)
            if (dateText != nil) {
                logShell.date = self.textToLongDateFormatter.date(from: dateText!)
            }
            
            var lineIndex: String.Index? = self.file!.lines[fileIndex].startIndex
            
            if(logShell.date != nil) {
                //title
                lineIndex = self.readLineChunk(fileIndex: fileIndex, lineIndex: lineIndex, savedChunk: &logShell.title)
                //skip Info and Debug
                if(logShell.title == "INFO" || logShell.title == "DEBUG") {
                    discarded += 1
                    continue
                }
            } else {
                addToTrace(logArray: &newLogArray, lastInsertedFileIndex: &lastInsertedFileIndex, lastInsertedLogIndex: lastInsertedLogIndex, fileIndex: fileIndex)
                continue
            }
            
            if(lineIndex != nil) {
                //thread
                lineIndex = self.readLineChunk(fileIndex: fileIndex, lineIndex: lineIndex, savedChunk: &logShell.thread)
            } else {
                addToTrace(logArray: &newLogArray, lastInsertedFileIndex: &lastInsertedFileIndex, lastInsertedLogIndex: lastInsertedLogIndex, fileIndex: fileIndex)
                continue
            }
            
            if(lineIndex != nil) {
                //process
                lineIndex = self.readLineChunk(fileIndex: fileIndex, lineIndex: lineIndex, savedChunk: &logShell.process)
            } else {
                addToTrace(logArray: &newLogArray, lastInsertedFileIndex: &lastInsertedFileIndex, lastInsertedLogIndex: lastInsertedLogIndex, fileIndex: fileIndex)
                continue
            }
            
            if(lineIndex != nil) {
                //text
                logShell.text = self.file!.lines[fileIndex][lineIndex!...]
                    .dropFirst(3).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                addToTrace(logArray: &newLogArray, lastInsertedFileIndex: &lastInsertedFileIndex, lastInsertedLogIndex: lastInsertedLogIndex, fileIndex: fileIndex)
                continue
            }
            
            //search logs for the text of the new log and add it if found
            let updatedIndex = self.updateExistingLog(newLogArray: newLogArray, logShell: logShell, fileIndex: fileIndex)
            
            if(updatedIndex != nil) {
                lastInsertedLogIndex = updatedIndex!
                lastInsertedFileIndex = fileIndex
            } else {
                //add new log
                let newLogRecord = Log(lineNum: [fileIndex],
                                       dateAtLine: [fileIndex : logShell.date],
                                       title: DataHelper.stringToTitle(logShell.title),
                                       threadAtLine: [fileIndex : logShell.thread],
                                       process: logShell.process,
                                       text: logShell.text,
                                       traceAtLine: [fileIndex : logShell.text],
                                       showDetails: false)
                
                lastInsertedLogIndex = newLogArray.count
                lastInsertedFileIndex = fileIndex
                newLogArray.append(newLogRecord)
            }
        }
        print("Load logs result, lines: \(self.file!.lines.count - startIndex), logs: \(newLogArray.count), discarded: \(discarded)")
        return newLogArray
    }
    
    private func readLineChunk(fileIndex: Int, lineIndex: String.Index?, savedChunk: inout String) -> String.Index? {
        if(lineIndex != nil) {
            let chunkStart = self.file!.lines[fileIndex][lineIndex!...].firstIndex(of: "[")
            if(chunkStart != nil) {
                let chunkEnd = self.file!.lines[fileIndex][chunkStart!...].firstIndex(of: "]")
                if(chunkEnd != nil) {
                    savedChunk = self.file!.lines[fileIndex][chunkStart!...chunkEnd!]
                        .dropFirst().dropLast()
                        .trimmingCharacters(in: .whitespaces)
                    return chunkEnd
                }
            }
        }
        return nil
    }
                
    private func addToTrace(logArray: inout [Log], lastInsertedFileIndex: inout Int, lastInsertedLogIndex: Int, fileIndex: Int) {
        if(logArray.count != 0 &&
           lastInsertedFileIndex == fileIndex - 1) {
            logArray[lastInsertedLogIndex].traceAtLine[logArray[lastInsertedLogIndex].lineNum.last!]?.append("\n\(self.file!.lines[fileIndex])")
            lastInsertedFileIndex += 1
        }
    }
    
    private func updateExistingLog(newLogArray: [Log], logShell: LogShell, fileIndex: Int) -> Int? {
        var updatedIndex: Int?
        if (newLogArray.count != 0) {
            for logIndex in 0...newLogArray.count - 1 {
                
                //Remove numbers from text before comparing text process and title
                if (newLogArray[logIndex].text.components(separatedBy: CharacterSet.decimalDigits).joined() == logShell.text.components(separatedBy: CharacterSet.decimalDigits).joined() &&
                    newLogArray[logIndex].process == logShell.process &&
                    newLogArray[logIndex].title.rawValue == logShell.title) {
                    
                    updatedIndex = logIndex
                    //Add line number
                    newLogArray[logIndex].lineNum.append(fileIndex)
                    //Add date at line
                    newLogArray[logIndex].dateAtLine.updateValue(logShell.date, forKey: fileIndex)
                    //Add thread at line
                    newLogArray[logIndex].threadAtLine.updateValue(logShell.thread, forKey: fileIndex)
                    //Start trace at line
                    newLogArray[logIndex].traceAtLine.updateValue(logShell.text, forKey: fileIndex)
                    continue
                                                                        
                    //data check
                    //if(log[logIndex].process != lineChunks[3]) {print("Process mismatch from line \(fileIndex) : \(lineChunks[3]) vs \(log[logIndex].process)")}
                }
            }
        }
        return updatedIndex
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
            return "\(DataHelper.dateToShortTextFormatter.string(from: log.dateAtLine[log.lineNum[0]]!!)) - " +
                "\(DataHelper.dateToShortTextFormatter.string(from: log.dateAtLine[log.lineNum[log.lineNum.count - 1]]!!))"
        } else {
            return "\(DataHelper.dateToShortTextFormatter.string(from: log.dateAtLine[log.lineNum[0]]!!))"
        }
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

extension Int: @retroactive Identifiable{
    public var id: Int {
        return self
    }
}

extension URL {
    var isDirectory: Bool {
       (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}
