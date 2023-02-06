//
//  File.swift
//  LogParser
//
//  Created by Tyler Wilson on 3/6/20.
//  Copyright © 2020 Tyler Wilson. All rights reserved.
//

import Foundation
import AppKit

extension String: Identifiable {
    public var id: String {
        return self
    }
}

class File {

    private let fileContent: NSString
    private let path: String
    public var lines: [String]
    
    func getPath() -> String {
        return path
    }

    init?(path: String, delimiter: String = "\n") {
        
        print("Opening path: \(path)")
        self.path = path
        
        do {
            fileContent = try NSString(contentsOfFile: self.path, encoding: String.Encoding.ascii.rawValue)
        } catch {
            print("Failed to open file \(self.path)")
            print(error.localizedDescription)
            return nil
        }
        
        //Seperate by line
        lines = fileContent.components(separatedBy: delimiter)
    }
}
