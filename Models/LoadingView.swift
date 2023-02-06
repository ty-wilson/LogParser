//
//  LoadingView.swift
//  LogParser
//
//  Created by Tyler Wilson on 4/11/20.
//  Copyright © 2020 Tyler Wilson. All rights reserved.
//

import SwiftUI

struct LoadingView: View, DropDelegate {
    @EnvironmentObject var fileHandler: FileHandler
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
            
            loadingViewMessage(fileHandler)
                .frame(width: 400, height: 50)
            
            /*DatePicker(
                    "Start Date",
                    selection: $date,
                    displayedComponents: [.date]
            )
            .datePickerStyle(GraphicalDatePickerStyle())*/
            
            Spacer()
        }.onDrop(of: [(kUTTypeFileURL as String)], delegate: self)
            Spacer()
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {

        guard let itemProvider = info.itemProviders(for: [(kUTTypeFileURL as String)]).first else { return false }
            
        itemProvider.loadItem(forTypeIdentifier: (kUTTypeFileURL as String), options: nil) {item, error in
            guard let thisData = item as? Foundation.Data, let url = URL(dataRepresentation: thisData, relativeTo: nil) else { return }
                   
            if(self.fileHandler.status == .waiting) {
                self.fileHandler.loadFile(filePath: url.path)
                UI {
                    window.title = "\(url.path)"
                }
            }
        }

        return true
    }
}

private func loadingViewMessage(_ fileHandler: FileHandler) -> AnyView {
    switch fileHandler.status {
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
    @EnvironmentObject var fileHandler: FileHandler
    
    var body: some View {
            HStack {
                Text("Drag and drop a file, or")
                    .foregroundColor(.secondary)
                Button("Select File...", action: {
                    UI {
                        let path: String?
                        
                        let openPanel = NSOpenPanel()
                        openPanel.makeKeyAndOrderFront(nil)
                        openPanel.level = .modalPanel
                        
                        let response = openPanel.runModal()
                        
                        if ( response == NSApplication.ModalResponse.OK )
                        {
                            path = openPanel.url!.path
                        }
                        else {
                            path = nil
                        }
                            
                        if(path != nil) {
                            self.fileHandler.loadFile(filePath: path!)
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
    @EnvironmentObject var fileHandler: FileHandler
    
    var body: some View {
        VStack {
            Text("\(fileHandler.status.toString(fileHandler: fileHandler))")
            if(fileHandler.status == .loading_dates) {
                Text("%" + String(format: "%.2f", fileHandler.percentDatesLoaded) + " | dates: \(fileHandler.numDatesLoaded)")
            } else if (fileHandler.status == .loading_logs) {
                Text("%" + String(format: "%.2f", fileHandler.percentLogsLoaded) + " | logs: \(fileHandler.numLogsLoaded)")
            }
        }
    }
}

public struct HLoadingView: View {
    @EnvironmentObject var fileHandler: FileHandler
    
    public var body: some View {
        HStack {
            if(self.fileHandler.status == .reloading) {
                Text("\(fileHandler.status.toString(fileHandler: fileHandler))")
                Text("%" + String(format: "%.2f", fileHandler.percentLogsLoaded) + " | logs: \(fileHandler.numLogsLoaded)")
            } else {
                EmptyView()
            }
        }
        .background(Color.primaryColor)
        .padding(5)
    }
}
