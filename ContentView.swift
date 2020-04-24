//
//  ContentView.swift
//  LogParser
//
//  Created by Tyler Wilson on 3/6/20.
//  Copyright © 2020 Tyler Wilson. All rights reserved.
//

import SwiftUI
import AppKit

extension Color {
    static let oldPrimaryColor = NSColor.systemIndigo
    static let primaryColor = Color(NSColor(named: "PrimaryColor")!)
    static let uiRed = Color(NSColor(named: "UIRed")!)
    static let uiBlue = Color(NSColor(named: "UIBlue")!)
    static let uiGreen = Color(NSColor(named: "UIGreen")!)
    static let uiPurple = Color(NSColor(named: "UIPurple")!)
}

struct ContentView: View {
    @EnvironmentObject var data: Data
 
    @State public var filter = Filter(
        showErrors: true,
        showWarns: false,
        startingDate: Date())
    
    let window: NSWindow
    
    var body: some View {
        
        VStack {
            if(data.status != .loaded && data.status != .reloading) {
                loadingView(data, filter: $filter)
            } else {
                HStack {
                    //Date picker and reload button
                    datePickerView(filter: $filter).environmentObject(data)
                    
                    //Reloading status
                    if(data.status == .reloading) {
                        HLoadingView().environmentObject(data)
                    }
                    
                    Spacer()
                    
                    Text(String(data.getNumFilteredLogs(filter: filter)) + " logs: ")
                        .foregroundColor(.white)
                        .bold()
                    
                    //Filters
                    Toggle("Show Errors", isOn: $filter.showErrors)
                    Toggle("Show Warns", isOn: $filter.showWarns)
                }
                .padding([.top, .leading, .trailing], 8)
                
                //Log View
                LogView(logArray: data.getLogs(filter: filter)!)
                    .background(Color.primaryColor)
                    .onAppear() {
                        print("Setting window... \(self.window.screen!.visibleFrame)")
                        //Maximize window on screen
                        self.window.setFrame(self.window.screen!.visibleFrame, display: true)
                        //Set to resizable
                        self.window.styleMask = [.resizable, .titled, .closable, .miniaturizable, .fullSizeContentView]
                    }
            }
        }
        .onAppear() {
            print("ContentView loaded")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(window: NSWindow()).environmentObject(Data())
    }
}
