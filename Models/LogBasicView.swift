//
//  LogBasicView.swift
//  Log Parser
//
//  Created by Tyler Wilson on 3/16/23.
//  Copyright © 2023 Tyler Wilson. All rights reserved.
//

import SwiftUI

@available(macOS 11.0, *)
struct LogBasicView: View {
    @EnvironmentObject var filter: Filter
    @StateObject var log: Log
    
    var body: some View {
        HStack(alignment: .center) {
            HStack {
                //number of lines
                Text(String(log.lineNum.count) + "x")
                    .foregroundColor(Color.secondary)
                
                //title
                Text(verbatim: log.title.rawValue).foregroundColor(colorTitle(title: log.title))
                
                //process
                StyledText(verbatim: log.process)
                    .style(.highlight(), ranges: {
                        filter.ignoreCase ? $0.lowercased().ranges(of: filter.searchText.lowercased()) : $0.ranges(of: filter.searchText)
                    })
                    .foregroundColor(Color.uiGreen)
                
                //text
                StyledText(verbatim: log.text)
                    .style(.highlight(), ranges: {
                        filter.ignoreCase ? $0.lowercased().ranges(of: filter.searchText.lowercased()) : $0.ranges(of: filter.searchText)
                    })
                    .foregroundColor(Color.uiWhite)
            }
            
            Spacer()
            
            //date range
            StyledText(verbatim: DataHelper.dateRangeText(log))
                .style(.highlight(), ranges: {
                        filter.ignoreCase ? $0.lowercased().ranges(of: filter.searchText.lowercased()) : $0.ranges(of: filter.searchText)
                    })
                .foregroundColor(.uiBlue)
        }
    }
}

@available(macOS 11.0, *)
struct LogBasicView_Previews: PreviewProvider {
    static var previews: some View {
        LogBasicView(log: Log(lineNum: [1, 2],
                              dateAtLine: [1 : Date(), 2 : Date()],
                              title: .ERROR,
                              threadAtLine: [ 1 : "ThreadName" , 2 : "OtherThread"],
                              process: "ProcessName",
                              text: "Text Here",
                              traceAtLine: [ 1 : "\nTrace here", 2 : "\nAnother trace here"],
                              showDetails: true))
    }
}
