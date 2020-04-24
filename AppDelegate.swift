//
//  AppDelegate.swift
//  LogParser
//
//  Created by Tyler Wilson on 3/6/20.
//  Copyright © 2020 Tyler Wilson. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let data = Data()

        // Create the window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false) 
        window.setFrameAutosaveName("Main Window")
        window.makeKeyAndOrderFront(nil)
        
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView(window: window).environmentObject(data)
        
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

