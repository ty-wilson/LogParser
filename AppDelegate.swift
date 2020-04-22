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
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    var window: NSWindow!
    let data = Data()

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // Create the window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false) 
        window.setFrameAutosaveName("Main Window")
        window.makeKeyAndOrderFront(nil)
        window.delegate = self
        
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView(window: window, firstLoad: true).environmentObject(data)
        
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
    }
    
    /*func windowDidResize(_ notification: Notification) {
        //Reset the contentView when resized
        let contentView = ContentView(window: window!, firstLoad: false).environmentObject(data)
        window.contentView = NSHostingView(rootView: contentView)
    }*/
    
    func windowDidEndLiveResize(_ notification: Notification) {
        let contentView = ContentView(window: window!, firstLoad: false).environmentObject(data)
        window.contentView = NSHostingView(rootView: contentView)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

