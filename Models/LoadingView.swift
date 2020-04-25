//
//  LoadingView.swift
//  LogParser
//
//  Created by Tyler Wilson on 4/11/20.
//  Copyright © 2020 Tyler Wilson. All rights reserved.
//

import SwiftUI

let SECONDS_PER_DAY = 86400

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

struct waitingView: View {
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
                Text("")
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
                }).buttonStyle(BorderedButtonStyle())
                Spacer()
            }
            Spacer()
        }
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
            Text("\(data.status.toString()) ")
            Text("\(data.message ?? "no message")")
        }
    }
}
