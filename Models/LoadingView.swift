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

struct datePickerView: View {
    @EnvironmentObject var data: Data
    @Binding var filter: Filter
    @State var numberDaysToLoad = 0
    
    var limitingDate: Date {
        return Date(timeIntervalSinceNow: Double(-1 * numberDaysToLoad) * TimeInterval(SECONDS_PER_DAY))
    }
    var maximumNumberOfDaysAgo: Int {
        return Int(data.loadingDatesData.shortDatesList[0].distance(to: Date())) / SECONDS_PER_DAY
    }
    var minimumNumberOfDaysAgo: Int {
        return Int(data.loadingDatesData.shortDatesList[data.loadingDatesData.shortDatesList.count - 1].distance(to: Date())) / SECONDS_PER_DAY
    }
    
    var body: some View {
        HStack {
            Picker(selection: $numberDaysToLoad, label: Text("")) {
                ForEach(minimumNumberOfDaysAgo...maximumNumberOfDaysAgo) {
                    Text(self.generatePickerTextFor(daysAgo: $0))
                }
            }
            .fixedSize()
            .disabled(data.status != .loaded)
            
            Button ("Reload") {
                self.filter.startingDate = self.data.loadingDatesData.convertToShortDate(self.limitingDate)
                self.data.loadLogs(filter: self.filter)
            }
            .disabled(data.status != .loaded)
        }
        .onAppear() {
            self.numberDaysToLoad = self.minimumNumberOfDaysAgo
        }
    }
    
    //Finds the date and number of logs to display per line in the view with format:
    // 33 days ago (2020-01-01 | XXXX logs)
    // or
    // 33 days ago (2020-01-01 | +XXXX logs = YYYY)
    func generatePickerTextFor(daysAgo: Int) -> String {
        var text = String()
        if(daysAgo == 0) {
            text.append("Today: " + dateToString(Date()) + " | " + Data.getFormattedNumber(self.data.loadingDatesData.occurancesAt(Date())) + " logs")
        } else {
            //Date
            text.append(dateToString(getDateFromToday(-1 * daysAgo)) + " | ")
            //Logs
            text.append(Data.getFormattedNumber(self.data.loadingDatesData.occurancesAfterAndIncluding(getDateFromToday(-1 * daysAgo))) + " logs")
        }
        
        return text
    }
    
    func getDateFromToday(_ deltaDays: Int) -> Date {
        return Date(timeIntervalSinceNow: TimeInterval(deltaDays * SECONDS_PER_DAY))
    }
    
    func dateToString(_ date: Date) -> String {
        let text = date.description
        return String(text[...text.firstIndex(of: " ")!]).trimmingCharacters(in: .whitespaces)
    }
}
