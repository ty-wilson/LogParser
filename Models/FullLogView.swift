//
//  FullLogView.swift
//  Log Parser
//
//  Created by Tyler Wilson on 2/6/23.
//  Copyright © 2023 Tyler Wilson. All rights reserved.
//

import SwiftUI

struct FullLogView: View {
    @EnvironmentObject var dataHelper: DataHelper
    @State var fullLogText: String = ""
    var fullLogLine: Int
    @State var window: NSWindow
    
    var body: some View {
        Text(String(fullLogLine))
        ScrollView {
            VStack {
                Text(fullLogText).frame(maxWidth: .infinity)
            }.padding()
        }.onAppear() {
            do {
                try fullLogText = dataHelper.getFileAsText()
            } catch {
                self.window.close()
            }
        }
    }
}

struct FullLogView_Previews: PreviewProvider {
    static var previews: some View {
        FullLogView(fullLogText: "", fullLogLine: 1, window: NSWindow())
            .environmentObject(DataHelper())
    }
}
