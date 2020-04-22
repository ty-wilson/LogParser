//
//  LogView.swift
//  LogParser
//
//  Created by Tyler Wilson on 3/9/20.
//  Copyright © 2020 Tyler Wilson. All rights reserved.
//

import SwiftUI

struct LogView: View {
    var page: [Log]
    let window: NSWindow
    @Binding var pageSize: Int
    
    var body: some View {
        VStack {
            HStack {
                if(pageSize == 0){Spacer()}
                //Scroll View of Line Views
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(page) { log in
                            LineView(log: log)
                            Divider()
                        }
                    }
                    .padding([.top, .leading, .trailing], 10)
                }
                .onAppear(){
                    print("LogView appeared, sizing: " + String(Int(self.window.frame.height / 35) - 2))
                    self.pageSize = Int(self.window.frame.height / 35) - 2
                }
                if(pageSize == 0){Spacer()}
            }
        }
    }
}
