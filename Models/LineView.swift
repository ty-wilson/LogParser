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
    @State var log: Log

    @State var selectedLineNum: Int?
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
                    
                    colorTitle(title: log.title)
                    Text(log.process).foregroundColor(Color.uiGreen)
                    Text(log.text).foregroundColor(.white).lineLimit(1)
                    
                    Spacer()
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
                
                Button(dateRangeText + "  ⓘ", action: {
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
                HSplitView() {
                    //Line | Date | Thread
                    VStack(alignment: .trailing) {
                        List (log.lineNum, selection: $selectedLineNum) { num in
                            HStack {
                                //Add line, date and thread
                                
                                Text("line \(num):")
                                .foregroundColor(.secondary)
                                .padding(2)
                                Text("\(Data.dateToLongTextFormatter.string(from: self.log.dateAtLine[num]!!))")
                                    .foregroundColor(Color.uiBlue)
                                Text("[\(self.log.threadAtLine[num]!)]")
                                    .foregroundColor(Color.uiPurple)
                            }
                        }
                        .frame(minHeight: detailsMinHeight)
                    }.padding([.top, .bottom], 10)
                    .frame(idealWidth: 650)
                    
                    //Text: Combine text with other text
                    if(selectedLineNum != nil) {
                        HStack {
                            VStack(alignment: .leading) {
                                
                                Text("Trace:").bold().foregroundColor(Color.secondary)
                                resettingTextField(text: log.traceAtLine[selectedLineNum!]!,
                                                   savedText: log.traceAtLine[selectedLineNum!]!)
                                
                                //Button
                                    Button("Open in Terminal", action: {
                                    var error: NSDictionary?
                                    if let scriptObject = NSAppleScript(source: "tell app \"Terminal\" to do script \"nano +\(self.selectedLineNum! + 1) '\(self.data.getFilePath())'\"") {
                                            if let _: NSAppleEventDescriptor = scriptObject.executeAndReturnError(
                                                                                                               &error) {
                                                //print(output.stringValue)
                                            } else if (error != nil) {
                                                print("error: \(String(describing: error))")
                                            }
                                        }
                                    
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
                            .padding(.leading, 5)
                            Spacer()
                        }
                        .frame(idealWidth: 900)
                    } else {
                        HStack {
                            VStack(alignment: .leading) {
                                
                                resettingTextField(text: "",
                                                   savedText: "")
                                Spacer()
                            }
                            Spacer()
                        }
                        .frame(idealWidth: 900)
                    }
                }
            }
        }
    }
}

struct resettingTextField: View {
    @State var text: String
    let savedText: String
    
    var body: some View {
        TextField("", text: $text)
            .frame(maxWidth: 1000)
            //prevent edits
            .onReceive([text].publisher.first()) { (value) in
                self.text = self.savedText
        }
            .background(Color.primaryColor)
    }
}

func colorTitle(title: Log.Title) -> Text? {
    if(title == .ERROR) {
        return Text(verbatim: title.rawValue).foregroundColor(.red)
    }
    if(title == .WARN) {
        return Text(verbatim: title.rawValue).foregroundColor(.yellow)
    }
    return nil
}

struct LineView_Previews: PreviewProvider {
    static var previews: some View {
        LineView(log: Log(lineNum: [1, 2],
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
