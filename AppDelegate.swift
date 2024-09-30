//
//  AppDelegate.swift
//  LogParser
//
//  Created by Tyler Wilson on 3/6/20.
//  Copyright © 2020 Tyler Wilson. All rights reserved.
//

import Cocoa
import SwiftUI

@available(macOS 11.0, *)
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        openNewWindow()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let myMenu = NSMenu(title: "Log Parser Menu")
        let myMenuItem = NSMenuItem(title: "New Log Parser Window", action:#selector(self.openNewWindow), keyEquivalent: "")
        myMenu.addItem(myMenuItem)
        return myMenu
    }

    @objc func openNewWindow() {
        // Create the window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.setFrameAutosaveName("Main Window")
        window.makeKeyAndOrderFront(nil)
        
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView(window: window)
        
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
    }
}

