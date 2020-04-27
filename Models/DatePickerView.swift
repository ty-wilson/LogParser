//
//  DatePickerView.swift
//  LogParser
//
//  Created by Tyler Wilson on 4/24/20.
//  Copyright © 2020 Tyler Wilson. All rights reserved.
//

import SwiftUI

struct datePickerView: View {
    @EnvironmentObject var data: Data
    @State var numberDaysToLoad: Int
    
    var limitingDate: Date {
        return Date(timeIntervalSinceNow: Double(-1 * numberDaysToLoad) * TimeInterval(SECONDS_PER_DAY))
    }
    var maximumNumberOfDaysAgo: Int {
        return Int(data.loadingDatesData.shortDatesList[0].d.distance(to: Date())) / SECONDS_PER_DAY
    }
    var minimumNumberOfDaysAgo: Int {
        return Int(data.loadingDatesData.shortDatesList[data.loadingDatesData.shortDatesList.count - 1].d.distance(to: Date())) / SECONDS_PER_DAY
    }
    
    var body: some View {
        HStack {
            //Date Picker
            Picker(selection: $numberDaysToLoad, label: EmptyView()) {
                ForEach(minimumNumberOfDaysAgo...maximumNumberOfDaysAgo) {
                    //Highlight the currently filtered date
                    if (self.data.loadingDatesData.convertToShortDate(self.getDateFromToday(minus: $0)).d
                        .compare(self.data.startingDate.d) == .orderedSame) {
                        Text(self.generatePickerTextFor(daysAgo: $0))
                            .foregroundColor(Color.uiGreen)
                    } else {
                        Text(self.generatePickerTextFor(daysAgo: $0))
                    }
                }
            }
            .fixedSize()
            .disabled(data.status != .loaded)
            .onReceive([self.numberDaysToLoad].publisher.first()) { (value) in
                if (self.data.loadingDatesData.convertToShortDate(self.getDateFromToday(minus: self.numberDaysToLoad)).d
                    .compare(self.data.startingDate.d) != .orderedSame) {
                    self.data.startingDate = self.data.loadingDatesData.convertToShortDate(self.limitingDate)
                    self.data.loadLogs()
                }
            }
        }
    }
    
    //Finds the date and number of logs to display per line in the view with format:
    // 33 days ago (2020-01-01 | XXXX logs)
    // or
    // 33 days ago (2020-01-01 | +XXXX logs = YYYY)
    func generatePickerTextFor(daysAgo: Int) -> String {
        var text = String()
        if (daysAgo == 0) {
            text.append("Today: " + dateToString(Date()) + " | " + Data.getFormattedNumber(self.data.loadingDatesData.occurancesAt(Date())) + " logs")
        } else {
            //Date
            text.append(dateToString(getDateFromToday(minus: daysAgo)) + ": ")
            //Logs
            text.append(Data.getFormattedNumber(self.data.loadingDatesData.occurancesAfterAndIncluding(getDateFromToday(minus: daysAgo))) + " logs")
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
