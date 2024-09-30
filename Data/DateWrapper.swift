//
//  DateWrapper.swift
//  Log Parser
//
//  Created by Tyler Wilson on 2/5/23.
//  Copyright © 2023 Tyler Wilson. All rights reserved.
//

import Foundation

struct DateWrapper: Equatable, Hashable, Comparable {
    static func < (lhs: DateWrapper, rhs: DateWrapper) -> Bool {
        return lhs.d.compare(rhs.d) != .orderedDescending
    }
    
    let d: Date
}
