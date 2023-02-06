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
    static let uiOrange = Color(NSColor(named: "UIOrange")!)
    static let uiWhite = Color(NSColor(named: "UIWhite")!)
}

@available(macOS 11.0, *)
struct ContentView: View {
    @StateObject var fileHandler = FileHandler()
    @StateObject var filter = Filter()
    
    let window: NSWindow
    
    var body: some View {
        
        VStack {
            if(fileHandler.status != .loaded && fileHandler.status != .reloading) {
                LoadingView(window: window)
            } else {
                FilterView()
                    .padding([.top, .leading, .trailing], 8)
                    .frame(minWidth: 650)
                
                LogListView()
                    .background(Color.primaryColor)
                    .onAppear() {
                        print("Setting window... \(self.window.screen!.visibleFrame)")
                        //Maximize window on screen
                        self.window.setFrame(self.window.screen!.visibleFrame, display: true)
                        //Set to resizable
                        self.window.styleMask = [.resizable, .titled, .closable, .miniaturizable, .fullSizeContentView]
                    }
                .overlay(HLoadingView(), alignment: .topTrailing)
            }
        }
        .onAppear() {
            print("ContentView loaded")
        }
        .environmentObject(filter)
        .environmentObject(fileHandler)
    }
}

@available(macOS 11.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(window: NSWindow())
            .environmentObject(FileHandler())
    }
}
