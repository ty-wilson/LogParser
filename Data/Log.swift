//
//  Log.swift
//  Log Parser
//
//  Created by Tyler Wilson on 2/5/23.
//  Copyright © 2023 Tyler Wilson. All rights reserved.
//

import Foundation

//struct Log: Hashable, Identifiable {
class Log: ObservableObject, Identifiable {
    
    init(lineNum: [Int],
         dateAtLine: Dictionary<Int, Date?>,
         title: Title,
         threadAtLine: Dictionary<Int, String>,
         process: String,
         text: String,
         traceAtLine: Dictionary<Int, String>,
         showDetails: Bool) {
        self.lineNum = lineNum
        self.dateAtLine = dateAtLine
        self.title = title
        self.threadAtLine = threadAtLine
        self.process = process
        self.text = text
        self.traceAtLine = traceAtLine
        self.showDetails = showDetails
    }
    
    var id: Int {
        return dateAtLine.keys.first!
    }
    
    enum Title: String {
        case ERROR
        case WARN
        case INFO
        case FATAL
        case MISSING
    }
    
    func getFirstDate() -> Date? {
        return dateAtLine[dateAtLine.keys.first!]!
    }
    
//    mutating func toggleDetails() {
//        showDetails = !showDetails
//    }
    
    func toggleDetails() {
        showDetails = !showDetails
    }
    
    var lineNum: [Int]
    var dateAtLine: Dictionary<Int, Date?>
    let title: Title
    var threadAtLine: Dictionary<Int, String>
    let process: String
    let text: String
    var traceAtLine: Dictionary<Int, String>
    @Published var showDetails: Bool
}
