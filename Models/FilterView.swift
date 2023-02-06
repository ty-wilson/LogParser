//
//  FilterView.swift
//  Log Parser
//
//  Created by Tyler Wilson on 2/3/23.
//  Copyright © 2023 Tyler Wilson. All rights reserved.
//

import SwiftUI

@available(macOS 11.0, *)
struct FilterView: View {
    @EnvironmentObject var filter: Filter
    @EnvironmentObject var fileHandler: FileHandler
    @State var showSettings = false
    
    var body: some View {
        //Top bar
        HStack {
            //Filters
            TextField("🔎 Search", text: $filter.searchText)
            
            //Search settings
            if(showSettings) {
                
                Toggle("Search traces", isOn: $filter.includeTrace)
                Toggle("Ignore case", isOn: $filter.ignoreCase)
                Toggle("ERROR", isOn: $filter.showErrors)
                    .foregroundColor(colorTitle(title: FileHandler.stringToTitle("ERROR")))
                Toggle("WARN", isOn: $filter.showWarns)
                    .foregroundColor(colorTitle(title: FileHandler.stringToTitle("WARN")))

                datePickerView(numberDaysToLoad: Int(fileHandler.startingDate.d.distance(to: Date())) / SECONDS_PER_DAY)
            }
            
            Button(action: {
                self.showSettings = !self.showSettings
            }) {
                if(self.showSettings) {
                    Image("GearOn")
                } else {
                    Image("GearOff")
                }
            }
            .buttonStyle(PlainButtonStyle())
            .onHover(perform: {val in
                if(val){
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            })
            
                
            Text(String(fileHandler.getNumFilteredLogs(filter: filter)) + " logs")
            .foregroundColor(.white)
            .bold()
        }
    }
}

@available(macOS 11.0, *)
struct FilterView_Previews: PreviewProvider {
    static var previews: some View {
        FilterView()
            .environmentObject(Filter())
            .environmentObject(FileHandler())
    }
}
