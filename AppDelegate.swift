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
        // Create the SwiftUI view that provides the window contents.

        //If aStreamReader cannot be initialized the app exits
        
        //let path = promptForPath()
        //exit if no path returned
        /*if(path == nil) {
            exit(0)
        }*/

        // Create the window and set the content view. 
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false) 
        window.setFrameAutosaveName("Main Window")
        window.makeKeyAndOrderFront(nil)
        window.delegate = self
        //window.setContentSize(window.contentMaxSize)
        
        let contentView = ContentView(window: window, firstLoad: true).environmentObject(data)
        
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
    }
    
    func windowDidResize(_ notification: Notification) {
        //Reset the contentView when resized
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

