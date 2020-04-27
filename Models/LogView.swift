//
//  LogView.swift
//  LogParser
//
//  Created by Tyler Wilson on 3/9/20.
//  Copyright © 2020 Tyler Wilson. All rights reserved.
//

import SwiftUI

struct LogView: View {

    var logArray: [Log]
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                //Scroll View of Line Views
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(logArray) { log in
                            LineView(log: log, selectedLineNum: log.lineNum[0],
                                     detailsMinHeight: CGFloat(50 + min(log.lineNum.count, 35) * 25))
                            Divider()
                        }
                    }
                    .padding([.top, .trailing], 10)
                }
 
                Spacer()
            }
        }
    }
}
