//
//  LoadingView.swift
//  LogParser
//
//  Created by Tyler Wilson on 4/11/20.
//  Copyright © 2020 Tyler Wilson. All rights reserved.
//

import SwiftUI

struct LoadingView: View, DropDelegate {
    @EnvironmentObject var dataHelper: DataHelper
    @State private var date = Date()
    
    let window: NSWindow
    
    var body: some View {
        HStack {
            Spacer()
        VStack {
            Spacer()
            
            Text("Log Parser")
                .bold()
            
            Spacer()
            
            Image(nsImage: NSImage(imageLiteralResourceName: "AppIcon"))
            
            Spacer()
            
            loadingViewMessage(dataHelper)
                .frame(width: 400, height: 50)
            
            Spacer()
        }.onDrop(of: [(kUTTypeFileURL as String)], delegate: self)
            Spacer()
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {

        guard let itemProvider = info.itemProviders(for: [(kUTTypeFileURL as String)]).first else { return false }
            
        itemProvider.loadItem(forTypeIdentifier: (kUTTypeFileURL as String), options: nil) {item, error in
            guard let thisData = item as? Foundation.Data, let url = URL(dataRepresentation: thisData, relativeTo: nil) else { return }
                   
            if(self.dataHelper.status == .waiting) {
                self.dataHelper.loadFile(url: url)
                UI {
                    window.title = "\(url.path)"
                }
            }
        }

        return true
    }
}

private func loadingViewMessage(_ dataHelper: DataHelper) -> AnyView {
    switch dataHelper.status {
        case .waiting:
            return AnyView(waitingView())
        case .loading_file:
            return AnyView(openingView())
        case .loading_dates:
            return AnyView(VLoadingView())
        case .loading_logs:
            return AnyView(VLoadingView())
        default:
            return AnyView(Text("An invalid status was passed to loadingView"))
    }
}

private struct waitingView: View {
    @EnvironmentObject var dataHelper: DataHelper
    
    var body: some View {
            HStack {
                Text("Drag and drop a file, or")
                    .foregroundColor(.secondary)
                Button("Select File...", action: {
                    UI {
                        let url: URL?
                        
                        let openPanel = NSOpenPanel()
                        openPanel.center()
                        openPanel.makeKeyAndOrderFront(nil)
                        openPanel.level = .modalPanel
                        
                        let response = openPanel.runModal()
                        
                        if ( response == NSApplication.ModalResponse.OK )
                        {
                            url = openPanel.url
                        }
                        else {
                            url = nil
                        }
                            
                        if(url != nil) {
                            self.dataHelper.loadFile(url: url!)
                        }
                    }
                })
                .onHover(perform: {val in
                    if(val){
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                })
            }
    }
}

private struct openingView: View {
    var body: some View {
        VStack {
            Text("")
            Text("Opening file...")
        }
    }
}

private struct VLoadingView: View {
    @EnvironmentObject var dataHelper: DataHelper
    
    var body: some View {
        VStack {
            Text("\(dataHelper.status.toString(dataHelper: dataHelper))")
            if(dataHelper.status == .loading_dates) {
                Text("File: \(dataHelper.getFilePath())")
                Text("%" + String(format: "%.2f", dataHelper.percentDatesLoaded) + " | dates: \(dataHelper.numDatesLoaded)")
            } else if (dataHelper.status == .loading_logs) {
                Text("%" + String(format: "%.2f", dataHelper.percentLogsLoaded) + " | logs: \(dataHelper.numLogsLoaded)")
            }
        }
    }
}

public struct HLoadingView: View {
    @EnvironmentObject var dataHelper: DataHelper
    
    public var body: some View {
        HStack {
            if(self.dataHelper.status == .reloading) {
                Text("\(dataHelper.status.toString(dataHelper: dataHelper))")
                Text("%" + String(format: "%.2f", dataHelper.percentLogsLoaded) + " | logs: \(dataHelper.numLogsLoaded)")
            } else {
                EmptyView()
            }
        }
        .background(Color.primaryColor)
        .padding(5)
    }
}
