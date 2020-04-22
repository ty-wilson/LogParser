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
    static let MAX_DETAIL_LINES = 500 //Max number of lines printed under details
    static let MAX_TEXT_CHARACTERS = 10000
    static let MAX_TEXT_LINES = 500
    static let MIN_DETAIL_LINES = 4 //Min number of lines printed under details
        
    public let log: Log

    @State var details = false
    @State var detailsHeight: CGFloat = 0
    
    var countText: String {
        if(log.lineNum.count > LineView.MAX_DETAIL_LINES) {
            return "x" + String(LineView.MAX_DETAIL_LINES) + "+"
        } else {
            return "x" + String(log.lineNum.count)
        }
    }
    
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

                Text(countText).foregroundColor(Color.uiGreen)
                
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
            
            //Detailed View
            if(details) {
                HStack(alignment: .top) {
                    //Line | Date | Thread
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach (log.lineNum[0...min(log.lineNum.count - 1, LineView.MAX_DETAIL_LINES)]) { num in
                                HStack {
                                    //Add line, date and thread
                                    Text("line \(num):")
                                        .foregroundColor(.gray)
                                    Text("\((self.log.dateAtLine[num]!)!)")
                                        .foregroundColor(Color.uiGreen)
                                    Text("[\(self.log.threadAtLine[num]!)]")
                                        .foregroundColor(.purple)
                                }.padding(5)//Each line padding
                            }
                        }.padding([.top, .bottom], 10)//Thread and time list padding
                    }
                    
                    Divider()
                    
                    //Text: Combine text with other text
                    ScrollView {
                        Text(String(Array(String(log.text + log.otherText))[...min((log.text.count + log.otherText.count - 1), LineView.MAX_TEXT_CHARACTERS)]))
                            .padding(15)//Text padding
                    }
                }
                .frame(maxHeight: 450)
                .padding(.leading, 20)//Indent
                .onAppear() {
                    //print("loaded \(self.log.lineNum)")
                    self.updateDetailsHeight()
                }
            }
        }
    }
    
    func updateDetailsHeight() {
        self.detailsHeight = CGFloat(min(max(self.log.lineNum.count - 1, LineView.MIN_DETAIL_LINES), LineView.MAX_DETAIL_LINES) * LineView.DETAIL_LINE_SIZE)
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
