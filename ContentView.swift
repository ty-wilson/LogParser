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
    static let uiDarkBlue = Color(NSColor(named: "UIDarkBlue")!)
    static let uiGreen = Color(NSColor(named: "UIGreen")!)
    static let uiPurple = Color(NSColor(named: "UIPurple")!)
    static let uiYellow = Color(NSColor(named: "UIYellow")!)
}

struct ContentView: View {
    @EnvironmentObject var data: Data
    @State public var filter = Filter(
        showErrors: true,
        showWarns: false,
        searchText: "",
        includeTrace: false,
        ignoreCase: true)
    @State var searchSettingsOn = false
    
    let window: NSWindow
    
    var body: some View {
        
        VStack {
            if(data.status != .loaded && data.status != .reloading) {
                loadingView().environmentObject(data)
            } else {
                //Top bar
                HStack {
                    //Filters
                    TextField("🔎 Search", text: $filter.searchText)
                    
                    //Search settings
                    if(searchSettingsOn) {
                        
                        Toggle("Search traces", isOn: $filter.includeTrace)
                        Toggle("Ignore case", isOn: $filter.ignoreCase)
                        Toggle("ERROR", isOn: $filter.showErrors)
                            .foregroundColor(Color.uiRed)
                        Toggle("WARN", isOn: $filter.showWarns)
                            .foregroundColor(.yellow)

                        //Date picker and reload button
                        datePickerView(numberDaysToLoad: Int(data.startingDate.d.distance(to: Date())) / SECONDS_PER_DAY).environmentObject(data)
                    }
                    
                    Button(action: {
                        self.searchSettingsOn = !self.searchSettingsOn
                    }) {
                        if(self.searchSettingsOn) {
                            Image("GearOn")
                        } else {
                            Image("GearOff")
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover(perform: {val in
                        if(val){
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    })
                    
                        
                    Text(String(data.getNumFilteredLogs(filter: filter)) + " logs")
                    .foregroundColor(.white)
                    .bold()
                }
                .padding([.top, .leading, .trailing], 8)
                .frame(minWidth: 650)
                
                //Log View
                LogView(filter: self.$filter, logArray: data.getFilteredLogs(filter: filter))
                    .background(Color.primaryColor)
                    .onAppear() {
                        print("Setting window... \(self.window.screen!.visibleFrame)")
                        //Maximize window on screen
                        self.window.setFrame(self.window.screen!.visibleFrame, display: true)
                        //Set to resizable
                        self.window.styleMask = [.resizable, .titled, .closable, .miniaturizable, .fullSizeContentView]
                    }
                .overlay(HLoadingView().environmentObject(data), alignment: .topTrailing)
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
