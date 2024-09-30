//
//  LogView.swift
//  LogParser
//
//  Created by Tyler Wilson on 3/9/20.
//  Copyright © 2020 Tyler Wilson. All rights reserved.
//

import SwiftUI

@available(macOS 11.0, *)
struct LogListView: View {
    @EnvironmentObject var filter: Filter
    @EnvironmentObject var dataHelper: DataHelper
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                //Scroll View of Line Views
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(dataHelper.getFilteredLogs(filter: filter)) { log in
                            LogView(log: log,
                                     detailsMinHeight: CGFloat(50 + min(log.lineNum.count, 35) * 25))
                            Divider()
                        }
                    }
                    .padding([.top, .trailing], 10)
                }
 
                Spacer()
            }
        }
        .onAppear() {
            print("LogView loaded")
        }
    }
}

@available(macOS 11.0, *)
struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogListView()
            .environmentObject(Filter())
            .environmentObject(DataHelper())
    }
}
