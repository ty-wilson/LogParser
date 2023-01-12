//
//  LineView.swift
//  LogParser
//
//  Created by Tyler Wilson on 3/13/20.
//  Copyright © 2022 Tyler Wilson. All rights reserved.
//

import SwiftUI

struct LineView: View {
    
    static let DETAIL_LINE_SIZE = 25 //Display size per detail log line
    static let MIN_DETAIL_LINES = 4 //Min number of lines printed under details
        
    @EnvironmentObject var data: Data
    @Binding var filter: Filter
    @State var log: Log

    @State var selectedLineNum: Int?
    @State var hasCopied = false
    let detailsMinHeight: CGFloat
    
    var opacity: Double {
        switch log.showDetails {
        case true:
            return 0.6
        default:
            return 1.0
        }
    }
    
    var body: some View {
        VStack {
            //Basic View
            HStack(alignment: .center) {
                HStack {
                    Text(String(log.lineNum.count) + "x")
                        .foregroundColor(Color.secondary)
                    
                    Text(verbatim: log.title.rawValue).foregroundColor(colorTitle(title: log.title))
                    StyledText(verbatim: log.process)
                        .style(.highlight(), ranges: {
                            filter.ignoreCase ? $0.lowercased().ranges(of: filter.searchText.lowercased()) : $0.ranges(of: filter.searchText)
                        })
                        .foregroundColor(Color.uiGreen)
                    StyledText(verbatim: log.text)
                        .style(.highlight(), ranges: {
                            filter.ignoreCase ? $0.lowercased().ranges(of: filter.searchText.lowercased()) : $0.ranges(of: filter.searchText)
                        })
                        .foregroundColor(Color.uiWhite)
                }.onHover(perform: {val in
                    if(val){
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                })
                .onTapGesture {
                        self.log.showDetails = !self.log.showDetails
                        self.data.toggleShowDetails(self.log)
                }
                
                Spacer()
                
                StyledText(verbatim: Data.dateRangeText(log))
                    .style(.highlight(), ranges: {
                            filter.ignoreCase ? $0.lowercased().ranges(of: filter.searchText.lowercased()) : $0.ranges(of: filter.searchText)
                        })
                    .foregroundColor(.uiBlue)
                    .onHover(perform: {val in
                        if(val){
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    })
                    .onTapGesture {
                            self.log.showDetails = !self.log.showDetails
                            self.data.toggleShowDetails(self.log)
                }
            }
            .padding(.trailing, 5)
            .opacity(opacity)
            
            //Detailed View
            if(log.showDetails) {
                HStack {
                    //Line | Date | Thread
                    VStack(alignment: .leading) {
                        List (log.lineNum, selection: $selectedLineNum) { num in
                            HStack {
                                //Add line, date and thread
                                
                                Text("line \(num):")
                                    .foregroundColor(.secondary)
                                StyledText(verbatim: "\(Data.dateToLongTextFormatter.string(from: self.log.dateAtLine[num]!!))")
                                    .style(.highlight(), ranges: { filter.includeTrace ? (filter.ignoreCase ? $0.lowercased().ranges(of: filter.searchText.lowercased()) : $0.ranges(of: filter.searchText)) : [] })
                                    .foregroundColor(Color.uiBlue)

                                StyledText(verbatim: "[\(self.log.threadAtLine[num]!)]")
                                    .style(.highlight(), ranges: { filter.includeTrace ? (filter.ignoreCase ? $0.lowercased().ranges(of: filter.searchText.lowercased()) : $0.ranges(of: filter.searchText)) : [] })
                                    .foregroundColor(Color.uiPurple)
                            }
                        }
                    }.padding([.top, .bottom], 10)
                    .frame(width: 460)
                    
                    //Text: Combine text with other text
                    if(selectedLineNum != nil) {
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    if #available(macOS 12.0, *) {
                                        Text("Trace at line \(selectedLineNum!):").bold().foregroundColor(Color.secondary).textSelection(.enabled)
                                    } else {
                                        Text("Trace at line \(selectedLineNum!):").bold().foregroundColor(Color.secondary)
                                    }
                                    
                                    Button("Open in Terminal", action: {
                                        let appleScript1 = "tell app \"Terminal\" to do script \"nano +\(self.selectedLineNum! + 1) '\(self.data.getFilePath())'\""
                                        let appleScript2 = "tell app \"Terminal\" to set bounds of front window to {0, 0, 1200, 9999} & activate"
                                        var error: NSDictionary?
                                        
                                        func executeScript(script: String){
                                            if let scriptObject = NSAppleScript(source: script) {
                                                if let output = scriptObject.executeAndReturnError(&error).stringValue {
                                                    print(output)
                                                } else if (error != nil) {
                                                    print("error: ", error!)
                                                }
                                            }
                                        }
                                        
                                        executeScript(script: appleScript1)
                                        executeScript(script: appleScript2)
                                        
                                    })
                                    .onHover(perform: {val in
                                        if(val){
                                            NSCursor.pointingHand.set()
                                        } else {
                                            NSCursor.arrow.set()
                                        }
                                    })
                                    
                                    Button("Copy to clipboard", action: {
                                        let pasteboard = NSPasteboard.general
                                        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                                        var stringToCopy = Data.dateToLongTextFormatter.string(from: self.log.dateAtLine[self.selectedLineNum!]!!) + " "
                                        stringToCopy += "[" + self.log.title.rawValue + "] "
                                        stringToCopy += "[" + self.log.threadAtLine[self.selectedLineNum!]! + "] "
                                        stringToCopy += "[" + self.log.process + "] - "
                                        stringToCopy += self.log.traceAtLine[self.selectedLineNum!]!
                                        pasteboard.setString(stringToCopy, forType: NSPasteboard.PasteboardType.string)
                                        self.hasCopied = true
                                    })
                                    .onHover(perform: {val in
                                        if(val){
                                            NSCursor.pointingHand.set()
                                        } else {
                                            NSCursor.arrow.set()
                                        }
                                    })
                                    
                                    Spacer()
                                }
                                .frame(minWidth: 350)
                                
                                if #available(macOS 12.0, *) {
                                    StyledText(verbatim: log.traceAtLine[selectedLineNum!]!)
                                        .style(.highlight(), ranges: { filter.includeTrace ? (filter.ignoreCase ? $0.lowercased().ranges(of: filter.searchText.lowercased()) : $0.ranges(of: filter.searchText)) : [] })
                                        .textSelection(.enabled)
                                        .frame(maxWidth: 800)
                                        .fixedSize()//magic to make the textbox fit
                                } else {
                                    StyledText(verbatim: log.traceAtLine[selectedLineNum!]!)
                                        .style(.highlight(), ranges: { filter.includeTrace ? (filter.ignoreCase ? $0.lowercased().ranges(of: filter.searchText.lowercased()) : $0.ranges(of: filter.searchText)) : [] })
                                        .frame(maxWidth: 800)
                                        .fixedSize()//magic to make the textbox fit
                                }
                                
                                Spacer()
                            }
                            
                            Spacer()
                        }.padding(.leading, 10)
                        .frame(idealWidth: 900)//more magic
                    } else {
                        HStack {
                            VStack(alignment: .leading) {
                                
                                Text(verbatim: "")
                                Spacer()
                            }
                            Spacer()
                        }
                        .frame(idealWidth: 900)
                    }
                }.frame(minHeight: detailsMinHeight)
                .fixedSize(horizontal: false, vertical: true)//magic
            }
        }
    }
}

func colorTitle(title: Log.Title) -> Color {
    switch title {
    case .ERROR:
        return .uiOrange
    case .WARN:
        return .uiYellow
    case .FATAL:
        return .uiRed
    case .INFO:
        return .white
    case .MISSING:
        return .white
    }
}

extension String {
    func indices(of occurrence: String) -> [Int] {
        var indices = [Int]()
        var position = startIndex
        while let range = range(of: occurrence, range: position..<endIndex) {
            let i = distance(from: startIndex,
                             to: range.lowerBound)
            indices.append(i)
            let offset = occurrence.distance(from: occurrence.startIndex,
                                             to: occurrence.endIndex) - 1
            guard let after = index(range.lowerBound,
                                    offsetBy: offset,
                                    limitedBy: endIndex) else {
                                        break
            }
            position = index(after: after)
        }
        return indices
    }
}

extension String {
    func ranges(of searchString: String) -> [Range<String.Index>] {
        let _indices = indices(of: searchString)
        let count = searchString.count
        return _indices.map({ index(startIndex, offsetBy: $0)..<index(startIndex, offsetBy: $0+count) })
    }
}

@available(macOS 12.0, *)
struct LineView_Previews: PreviewProvider {
    static var previews: some View {
        LineView(filter: .constant(Filter(showErrors: true, showWarns: true, searchText: "here", includeTrace: true, ignoreCase: true)), log:     Log(lineNum: [1, 2],
                    dateAtLine: [1 : Date(), 2 : Date()],
                    title: .ERROR,
                    threadAtLine: [ 1 : "ThreadName" , 2 : "OtherThread"],
                    process: "ProcessName",
                    text: "Text Here",
                    traceAtLine: [ 1 : "\nTrace here", 2 : "\nAnother trace here"],
                    showDetails: true),
                 selectedLineNum: 1, detailsMinHeight: 100)
    }
}
