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
    
    var arrowText: String {
        switch log.showDetails {
            case true: return " Ｖ "
            case false: return " ＞ "
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            //Basic View
            HStack(alignment: .top) {
                Button(arrowText, action: {
                    self.log.showDetails = !self.log.showDetails
                    self.data.toggleShowDetails(self.log)
                }).foregroundColor(Color.uiBlue)
                .buttonStyle(PlainButtonStyle())
                .overlay(Circle().stroke(Color.uiBlue, lineWidth: 1))
                    .shadow(color: Color.white, radius: 1)
                .onHover(perform: {val in
                    if(NSCursor.current == NSCursor.arrow){
                        NSCursor.pointingHand.set()
                    } else if(NSCursor.current == NSCursor.pointingHand) {
                        NSCursor.arrow.set()
                    }
                })
                .padding(1)

                Text(String(log.lineNum.count) + "x")
                    .foregroundColor(Color.secondary)
                
                colorTitle(title: log.title)
                Text(log.process).foregroundColor(Color.uiGreen)
                Text(log.text).foregroundColor(.white).lineLimit(1)
                
                Spacer()
                
                //Date Range
                if(log.lineNum.count > 1) {
                    Text("\(Data.dateToShortTextFormatter.string(from: log.dateAtLine[log.lineNum[0]]!!)) - " +
                        "\(Data.dateToShortTextFormatter.string(from: log.dateAtLine[log.lineNum[log.lineNum.count - 1]]!!))")
                        .foregroundColor(Color.uiBlue)
                } else {
                    Text ("\(Data.dateToShortTextFormatter.string(from: log.dateAtLine[log.lineNum[0]]!!))")
                        .foregroundColor(Color.uiBlue)
                }
            }
            .frame(alignment: .center)
            
            //Detailed View
            if(log.showDetails) {
                HStack(alignment: .top) {
                    //Line | Date | Thread
                    VStack(alignment: .leading) {
                        List (log.lineNum, selection: $selectedLineNum) { num in
                            HStack {
                                //Add line, date and thread
                                if(num == self.selectedLineNum) {
                                    Text("line \(num):")
                                        .foregroundColor(.black)
                                } else {
                                    Text("line \(num):")
                                        .foregroundColor(.secondary)
                                }
                                Text("\(Data.dateToLongTextFormatter.string(from: self.log.dateAtLine[num]!!))")
                                    .foregroundColor(Color.uiGreen)
                                Text("[\(self.log.threadAtLine[num]!)]")
                                    .foregroundColor(Color.uiPurple)
                            }.padding(3)//Each line padding
                        }
                        .frame(width: 600)
                    }.padding([.top, .bottom], 10)
                    .frame(minHeight: detailsMinHeight)
                    
                    //Text: Combine text with other text
                    if(selectedLineNum != nil) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("line \(selectedLineNum!)")
                                    .foregroundColor(.secondary)
                                Button("Open in nano", action: {
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
                                    .foregroundColor(.secondary)
                                    .onHover(perform: {val in
                                        if(NSCursor.current == NSCursor.arrow){
                                            NSCursor.pointingHand.set()
                                        } else if(NSCursor.current == NSCursor.pointingHand) {
                                            NSCursor.arrow.set()
                                        }
                                    })
                                    .padding(1)
                                }
                            
                            resettingTextField(text: log.traceAtLine[selectedLineNum!]!,
                                               savedText: log.traceAtLine[selectedLineNum!]!)
                                .frame(maxWidth: 1000)
                                //prevent edits
                                .onReceive([self.log].publisher.first()) { (value) in
                                    self.log = self.data.getLog(logToGet: self.log)!
                            }
                        }
                        .padding(10)//Text padding
                        .fixedSize()
                    }
                }
                .padding(.leading, 15)//Indent
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
