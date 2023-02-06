//
//  LoadingDatesData.swift
//  Log Parser
//
//  Created by Tyler Wilson on 2/5/23.
//  Copyright © 2023 Tyler Wilson. All rights reserved.
//

import Foundation

//Startup data
struct ParsedDates {
//    public var shortDatesList: [EquatableDate] //expects only short dates from convertToShortDate or textToShortDateFormatter
//    public var occurancesList: [Int]
//    public var firstIndexList: [Int]
    public var dateToOccurancesAndIndex: Dictionary<EquatableDate, OccurancesAndIndex>
    
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
    
    func contains(_ date: EquatableDate) -> Bool {
        return dateToOccurancesAndIndex[date] != nil
    }
    
    mutating func add(_ date: EquatableDate, occurances: Int, firstIndex: Int) {
        dateToOccurancesAndIndex[date] = OccurancesAndIndex(occurances: occurances, firstIndex: firstIndex)
    }
    
    mutating func addOccurance(_ date: EquatableDate) {
        dateToOccurancesAndIndex[date]?.occurances += 1
    }
    
    func getLast() -> EquatableDate {
        return dateToOccurancesAndIndex.keys.sorted(by: <).last!
    }
    
    func getFirst() -> EquatableDate {
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
    
    func getClosestIndexToDate(_ startingDate: EquatableDate) -> Int {
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

func convertToShortDate(_ date: Date) -> EquatableDate {
    let extraTime = Int(date.timeIntervalSince1970) % SECONDS_PER_DAY
    let newDate = Date(timeIntervalSince1970: TimeInterval(Int(date.timeIntervalSince1970) - extraTime))
    return EquatableDate(d: newDate)
}
