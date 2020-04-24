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
        
    public let log: Log

    @State var details = false
    @State var selectedLineNum: Int?
    let detailsMinHeight: CGFloat
    
    var arrowText: String {
        switch details {
            case true: return " Ｖ "
            case false: return " ＞ "
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            //Basic View
            HStack(alignment: .top) {
                Button(arrowText, action: {
                    self.details = !self.details
                }).foregroundColor(Color.uiGreen)
                .buttonStyle(PlainButtonStyle())
                .overlay(Circle().stroke(Color.uiGreen, lineWidth: 1))
                    .shadow(color: Color.white, radius: 1)

                Text(String(log.lineNum.count)).foregroundColor(Color.uiGreen)
                
                colorTitle(title: log.title)
                Text(log.process).foregroundColor(Color.uiBlue)
                Text(log.text).foregroundColor(.white).lineLimit(1)
                
                Spacer()
                
                //Date Range
                if(log.lineNum.count > 1) {
                    Text("\(Data.dateFormatter.string(from: log.dateAtLine[log.lineNum[0]]!!)) - " +
                        "\(Data.dateFormatter.string(from: log.dateAtLine[log.lineNum[log.lineNum.count - 1]]!!))")
                        .foregroundColor(Color.uiGreen)
                } else {
                    Text ("\(Data.dateFormatter.string(from: log.dateAtLine[log.lineNum[0]]!!))")
                        .foregroundColor(Color.uiGreen)
                }
            }
            .frame(alignment: .center)
            .onTapGesture {
                self.details = !self.details
            }
            
            //Detailed View
            if(details) {
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
                                Text("\((self.log.dateAtLine[num]!)!)")
                                    .foregroundColor(Color.uiGreen)
                                Text("[\(self.log.threadAtLine[num]!)]")
                                    .foregroundColor(Color.uiPurple)
                            }.padding(5)//Each line padding
                        }
                        .frame(width: 600)
                    }.padding([.top, .bottom], 10)
                    .frame(minHeight: detailsMinHeight)
                    
                    //Divider()
                    
                    //Text: Combine text with other text
                    if(selectedLineNum != nil) {
                        VStack(alignment: .leading) {
                            Text("line \(selectedLineNum!)")
                                .foregroundColor(.secondary)
                            Text(log.traceAtLine[selectedLineNum!]!)
                                .frame(maxWidth: 1000)
                        }
                        .padding(15)//Text padding
                        .fixedSize()
                    }
                }
                .padding(.leading, 20)//Indent
            }
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
                          traceAtLine: [ 1 : "\nTrace here", 2 : "\nAnother trace here"]),
                 details: true,
                 selectedLineNum: 1, detailsMinHeight: 100)
    }
}
