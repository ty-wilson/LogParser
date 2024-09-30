//
//  Status.swift
//  Log Parser
//
//  Created by Tyler Wilson on 2/6/23.
//  Copyright © 2023 Tyler Wilson. All rights reserved.
//

import Foundation

enum Status: String {
    case waiting
    case loading_file
    case loading_dates
    case loading_logs
    case loaded
    case reloading
    
    func toString(dataHelper: DataHelper) -> String {
        switch self {
            case .waiting:
                return "Waiting"
            case .loading_file:
                return "Opening file..."
            case .loading_dates:
                return "Checking for available dates..."
            case .loading_logs, .reloading:
                return "Parsing logs starting at \(DataHelper.dateToTextWithNoTimeFormatter.string(from: dataHelper.startingDate.d))..."
            case .loaded:
                return "Loaded"
        }
    }
}
