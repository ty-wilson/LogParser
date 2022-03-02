//
//  LineView.swift
//  LogParser
//
//  Created by Tyler Wilson on 3/13/20.
//  Copyright © 2020 Tyler Wilson. All rights reserved.
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
    
    var dateRangeText: String {
        if(log.lineNum.count > 1) {
            return "\(Data.dateToShortTextFormatter.string(from: log.dateAtLine[log.lineNum[0]]!!)) - " +
                "\(Data.dateToShortTextFormatter.string(from: log.dateAtLine[log.lineNum[log.lineNum.count - 1]]!!))"
        } else {
            return "\(Data.dateToShortTextFormatter.string(from: log.dateAtLine[log.lineNum[0]]!!))"
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
                    Text(log.process).foregroundColor(Color.uiGreen)
                    if(filter.ignoreCase) {
                        StyledText(verbatim: log.text)
                        .style(.highlight(), ranges: { $0.lowercased().ranges(of: filter.searchText.lowercased()) })
                        .foregroundColor(Color.uiWhite)
                    } else {
                        StyledText(verbatim: log.text)
                        .style(.highlight(), ranges: { $0.ranges(of: filter.searchText) })
                        .foregroundColor(Color.uiWhite)
                    }
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
                
                Button(dateRangeText, action: {
                    self.log.showDetails = !self.log.showDetails
                    self.data.toggleShowDetails(self.log)
                }).foregroundColor(.uiBlue)
                .buttonStyle(PlainButtonStyle())
                .onHover(perform: {val in
                    if(val){
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                })
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
                                Text("\(Data.dateToLongTextFormatter.string(from: self.log.dateAtLine[num]!!))")
                                    .foregroundColor(Color.uiBlue)
                                Text("[\(self.log.threadAtLine[num]!)]")
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
                                    Text("Trace at line \(selectedLineNum!):").bold().foregroundColor(Color.secondary)
                                    
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
                                        pasteboard.setString(self.log.traceAtLine[self.selectedLineNum!]!, forType: NSPasteboard.PasteboardType.string)
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
                                
                                if (filter.ignoreCase) {
                                    StyledText(verbatim: log.traceAtLine[selectedLineNum!]!)
                                        .style(.highlight(), ranges: { $0.lowercased().ranges(of: filter.searchText.lowercased()) })
                                        .frame(maxWidth: 800)
                                        .fixedSize()//magic to make the textbox fit
                                } else {
                                    StyledText(verbatim: log.traceAtLine[selectedLineNum!]!)
                                        .style(.highlight(), ranges: { $0.ranges(of: filter.searchText) })
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
