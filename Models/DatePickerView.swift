//
//  DatePickerView.swift
//  LogParser
//
//  Created by Tyler Wilson on 4/24/20.
//  Copyright © 2020 Tyler Wilson. All rights reserved.
//

import SwiftUI

struct datePickerView: View {
    @EnvironmentObject var fileHandler: FileHandler
    @State var numberDaysToLoad: Int
    
    var limitingDate: Date {
        return Date(timeIntervalSinceNow: Double(-1 * numberDaysToLoad) * TimeInterval(SECONDS_PER_DAY))
    }
    var maximumNumberOfDaysAgo: Int {
        return Int(fileHandler.parsedDates.getFirst().d.distance(to: Date())) / SECONDS_PER_DAY
    }
    var minimumNumberOfDaysAgo: Int {
        return Int(fileHandler.parsedDates.getLast().d.distance(to: Date())) / SECONDS_PER_DAY
    }
    
    var body: some View {
        HStack {
            //Date Picker
            Picker(selection: $numberDaysToLoad, label: EmptyView()) {
                ForEach(minimumNumberOfDaysAgo...maximumNumberOfDaysAgo) {
                    //Highlight the currently filtered date
                    if (convertToShortDate(self.getDateFromToday(minus: $0)).d
                        .compare(self.fileHandler.startingDate.d) == .orderedSame) {
                        Text(self.generatePickerTextFor(numDaysToSearch: $0))
                            .foregroundColor(Color.uiGreen)
                    } else {
                        Text(self.generatePickerTextFor(numDaysToSearch: $0))
                    }
                }
            }
            .fixedSize()
            .disabled(fileHandler.status != .loaded)
            .onReceive([self.numberDaysToLoad].publisher.first()) { (value) in
                if (convertToShortDate(self.getDateFromToday(minus: self.numberDaysToLoad)).d
                    .compare(self.fileHandler.startingDate.d) != .orderedSame) {
                    self.fileHandler.startingDate = convertToShortDate(self.limitingDate)
                    self.fileHandler.loadLogs()
                }
            }
        }
    }
    
    //Returns a string containing the date and number of total logs based on the number of total dates to be searched, staring with the latest date:
    // 33 days ago (YYYY-MM-DD | X total logs)
    func generatePickerTextFor(numDaysToSearch: Int) -> String {
        var text = String()
        if (numDaysToSearch == 0) {
            text.append("Today: " + dateToString(Date()) + " | " + FileHandler.getFormattedNumber(self.fileHandler.parsedDates.occurancesAt(Date())) + " logs")
        } else {
            //Date
            text.append(dateToString(getDateFromToday(minus: numDaysToSearch)) + ": ")
            //Logs
            text.append(FileHandler.getFormattedNumber(self.fileHandler.parsedDates.occurancesAfterAndIncluding(getDateFromToday(minus: numDaysToSearch))) + " logs")
        }
        
        return text
    }
    
    func getDateFromToday(minus deltaDays: Int) -> Date {
        return Date(timeIntervalSinceNow: TimeInterval(-deltaDays * SECONDS_PER_DAY))
    }
    
    func dateToString(_ date: Date) -> String {
        let text = date.description
        return String(text[...text.firstIndex(of: " ")!]).trimmingCharacters(in: .whitespaces)
    }
}
