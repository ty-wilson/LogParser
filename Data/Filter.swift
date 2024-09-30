//
//  Filter.swift
//  Log Parser
//
//  Created by Tyler Wilson on 2/3/23.
//  Copyright © 2023 Tyler Wilson. All rights reserved.
//

import Foundation

class Filter: ObservableObject {
    @Published var showErrors = true
    @Published var showWarns = true
    @Published var searchText = ""
    @Published var includeTrace = false
    @Published var ignoreCase = true
}
