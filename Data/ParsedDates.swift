//
//  LoadingDatesData.swift
//  Log Parser
//
//  Created by Tyler Wilson on 2/5/23.
//  Copyright © 2023 Tyler Wilson. All rights reserved.
//

import Foundation

struct ParsedDates {
    public var dateToOccurancesAndIndex: Dictionary<DateWrapper, OccurancesAndIndex>
    
    init() {
        dateToOccurancesAndIndex = Dictionary()
    }
    
    struct OccurancesAndIndex {
        var occurances: Int
        var firstIndex: Int
    }
    
    func count() -> Int {
        return dateToOccurancesAndIndex.count
    }
    
    func contains(_ date: DateWrapper) -> Bool {
        return dateToOccurancesAndIndex[date] != nil
    }
    
    mutating func addNewDate(_ date: DateWrapper, firstIndex: Int) {
        dateToOccurancesAndIndex[date] = OccurancesAndIndex(occurances: 1, firstIndex: firstIndex)
    }
    
    mutating func addOccurance(_ date: DateWrapper) {
        dateToOccurancesAndIndex[date]?.occurances += 1
    }
    
    func getLast() -> DateWrapper {
        return dateToOccurancesAndIndex.keys.sorted(by: <).last!
    }
    
    func getFirst() -> DateWrapper {
        return dateToOccurancesAndIndex.keys.sorted(by: <).first!
    }
    
    func occurancesAt(_ rawDate: Date) -> Int {
        let shortDate = convertToShortDate(rawDate)
        var occurances = 0
        
        if(dateToOccurancesAndIndex[shortDate] != nil){
            occurances = dateToOccurancesAndIndex[shortDate]!.occurances
        }
        
        return occurances
    }
    
    func occurancesAfterAndIncluding(_ rawDate: Date) -> Int {
        let shortDate = convertToShortDate(rawDate)
        var total = 0
        
        //Check if dates in the datesData are after the date and add the occurances from that date to the total
        for element in dateToOccurancesAndIndex {
            if(element.key.d.compare(shortDate.d) != .orderedAscending) {
                total += element.value.occurances
            }
        }
        
        return total
    }
    
    func getClosestIndexToDate(_ startingDate: DateWrapper) -> Int {
        var index = 0
        
        //Check if dates in the datesData are after the date and add the occurances from that date to the total
        for date in dateToOccurancesAndIndex.keys.sorted(by: <) {
            if(date.d.compare(startingDate.d) == .orderedDescending) {
                break;
            }
            index = dateToOccurancesAndIndex[date]!.firstIndex
        }
        
        return index
    }
}

func convertToShortDate(_ date: Date) -> DateWrapper {
    let extraTime = Int(date.timeIntervalSince1970) % SECONDS_PER_DAY
    let newDate = Date(timeIntervalSince1970: TimeInterval(Int(date.timeIntervalSince1970) - extraTime))
    return DateWrapper(d: newDate)
}
