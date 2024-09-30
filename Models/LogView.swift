//
//  LineView.swift
//  LogParser
//
//  Created by Tyler Wilson on 3/13/20.
//  Copyright © 2022 Tyler Wilson. All rights reserved.
//

import SwiftUI

@available(macOS 11.0, *)
struct LogView: View {
    static let DETAIL_LINE_SIZE = 25 //Display size per detail log line
    static let MIN_DETAIL_LINES = 4 //Min number of lines printed under details
        
    @EnvironmentObject var filter: Filter
    @StateObject var log: Log

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
            LogBasicView(log: log)
                .padding(.trailing, 5)
                .opacity(opacity)
                .onHover(perform: {val in
                    if(val){
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                })
                .onTapGesture {
                    self.log.showDetails = !self.log.showDetails
                }
            
            //Detailed View
            if(self.log.showDetails) {
                LogDetailsView(log: log)
                    .frame(minHeight: detailsMinHeight)
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
        LogView(log: Log(lineNum: [1, 2],
                    dateAtLine: [1 : Date(), 2 : Date()],
                    title: .ERROR,
                    threadAtLine: [ 1 : "ThreadName" , 2 : "OtherThread"],
                    process: "ProcessName",
                    text: "Text Here",
                    traceAtLine: [ 1 : "\nTrace here", 2 : "\nAnother trace here"],
                    showDetails: true),
                 detailsMinHeight: 100)
        .environmentObject(Filter())
        .environmentObject(DataHelper())
    }
}
