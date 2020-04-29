//
//  LoadingView.swift
//  LogParser
//
//  Created by Tyler Wilson on 4/11/20.
//  Copyright © 2020 Tyler Wilson. All rights reserved.
//

import SwiftUI

func loadingView(_ data: Data, filter: Binding<Filter>) -> AnyView {
    switch data.status {
        case .waiting:
            return AnyView(waitingView().environmentObject(data))
        case .loading_file:
            return AnyView(openingView())
        case .loading_dates:
            return AnyView(VLoadingView().environmentObject(data))
        case .loading_logs:
            return AnyView(VLoadingView().environmentObject(data))
        default:
            return AnyView(Text("An invalid status was passed to loadingView"))
    }
}

struct waitingView: View, DropDelegate {
    @EnvironmentObject var data: Data
    
    var body: some View {
        HStack {
            Spacer()
            VStack{
                Spacer()
                
                Text("Log Parser")
                    .bold()
                
                Spacer()
                
                Image(nsImage: NSImage(imageLiteralResourceName: "AppIcon"))
                
                Spacer()
                
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
                                self.data.loadFile(filePath: path!)
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
                
                Spacer()
            }
            Spacer()
        }.onDrop(of: [(kUTTypeFileURL as String)], delegate: self)
    }
    
    func performDrop(info: DropInfo) -> Bool {

        guard let itemProvider = info.itemProviders(for: [(kUTTypeFileURL as String)]).first else { return false }

        itemProvider.loadItem(forTypeIdentifier: (kUTTypeFileURL as String), options: nil) {item, error in
            guard let thisData = item as? Foundation.Data, let url = URL(dataRepresentation: thisData, relativeTo: nil) else { return }
            
            self.data.loadFile(filePath: url.path)
        }

        return true
    }
}

struct openingView: View {
    var body: some View {
        HStack {
            Spacer()
            VStack{
                Spacer()
                Text("Log Parser")
                    .bold()
                Spacer()
                Image(nsImage: NSImage(imageLiteralResourceName: "AppIcon"))
                Spacer()
                Text("")
                Text("Opening file...")
                Spacer()
            }
            Spacer()
        }
    }
}

struct VLoadingView: View {
    @EnvironmentObject var data: Data
    
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
                Text("\(data.status.toString())")
                Text("\(data.message ?? "no message")")
                Spacer()
            }
            Spacer()
        }
    }
}

struct HLoadingView: View {
    @EnvironmentObject var data: Data
    
    var body: some View {
        HStack {
            if(self.data.status == .reloading) {
                
                    Text("\(data.status.toString()) ")
                    Text("\(data.message ?? "no message")")
            } else {
                EmptyView()
            }
        }
        .background(Color.primaryColor)
        .padding(5)
    }
}
