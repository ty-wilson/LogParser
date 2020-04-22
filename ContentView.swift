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
    static let uiGreen = Color(NSColor(named: "UIGreen")!)
}

struct ContentView: View {
    @EnvironmentObject var data: Data
    @State private var pageNum: Int = 0
    @State public var pageSize = 0
    @State private var filter = Filter(
        showErrors: true,
        showWarns: false,
        startingDate: Date())
    
    let window: NSWindow
    var firstLoad: Bool
    
    var body: some View {
        
        VStack {
            if(data.status != .loaded && data.status != .reloading) {
                loadingView(data, filter: $filter)
            } else {
                HStack {
                    //Search
                    searchBarView(filter: $filter).environmentObject(data)
                    
                    if(data.status == .reloading) {
                        HLoadingView().environmentObject(data)
                    }
                    
                    Spacer()
                    
                    //Filters
                    Toggle("Show Errors", isOn: $filter.showErrors)
                    Toggle("Show Warns", isOn: $filter.showWarns)
                }
                .padding([.top, .leading, .trailing], 8)
                .onAppear() {
                    if(self.firstLoad) {
                        //Maximize window on screen
                        self.window.setFrame(self.window.screen!.visibleFrame, display: true)
                        //Resizable
                        self.window.styleMask = [.resizable, .titled, .closable, .miniaturizable, .fullSizeContentView]
                    }
                }
                
                //Log View
                if(data.hasPage(pageNum, pageSize: pageSize, filter: filter))
                {
                    LogView(page: data.getPage(pageNum, pageSize: pageSize, filter: filter)!, window: window, pageSize: $pageSize)
                        .background(Color.primaryColor)
                } else {
                    Spacer()
                    Text("No results on this page")
                        .onAppear() {
                            let newPage = self.data.getLastPage(pageSize: self.pageSize, filter: self.filter)
                            print("Resetting to \(newPage)")
                            self.pageNum = newPage
                        }
                    Spacer()
                }
                
                //Page Buttons
                HStack {
                    Spacer()
                    Button("First") {
                        self.pageNum = 0
                    }.padding(.bottom, 8)
                    .disabled(pageNum == 0)
                    Spacer()
                    Button("Previous") {
                        self.pageNum -= 1
                    }.padding([.leading, .bottom], 8)
                    .disabled(pageNum == 0)
                    Text("\((pageNum) * pageSize + 1) - \(min((pageNum + 1) * pageSize, self.data.getNumLogs(filter: filter)))|\(self.data.getNumLogs(filter: filter))")
                        .bold()
                        .padding(.bottom, 10)
                    Button("Next") {
                        self.pageNum += 1
                    }.padding([.trailing, .bottom], 10)
                        .disabled(!data.hasPage(pageNum + 1, pageSize: pageSize, filter: filter))
                    Spacer()
                    Button("Last") {
                        //search for last page
                        self.pageNum = self.data.getLastPage(pageSize: self.pageSize, filter: self.filter)
                    }.padding(.bottom, 10)
                        .disabled(!data.hasPage(pageNum + 1, pageSize: pageSize, filter: filter))
                    Spacer()
                }.frame(alignment: .top)
            }
        }
        .onAppear() {
            print("ContentView loaded")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(window: NSWindow(), firstLoad: true).environmentObject(Data())
    }
}
