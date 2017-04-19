//
//  File.swift
//  GetSchwifty
//
//  Created by Marius Landwehr on 19.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import Foundation

private let dateFormatter: DateFormatter = {
    let d = DateFormatter()
    d.timeStyle = .long
    d.dateStyle = .long
    return d
}()

class Schwifty {
    
    private enum CodingKeys: String {
        case Date
        case Name
        case Source
    }
    
    // MARK: - API
    var source: String
    var name: String
    private(set) var date: Date
    
    init(source: String, name: String? = nil) {
        self.source = source
        let date = Date()
        self.date = date
        self.name = name ?? dateFormatter.string(from: date)
    }
    
    // MARK: - Serialization
    
    init?(json: [String: Any]) {
        guard
            let date = json[CodingKeys.Date.rawValue] as? TimeInterval,
            let name = json[CodingKeys.Name.rawValue] as? String,
            let source = json[CodingKeys.Source.rawValue] as? String
        else {
            return nil
        }
        
        self.date = Date(timeIntervalSince1970: date)
        self.name = name
        self.source = source
    }
    
    var json: [String: Any] {
        return [
            CodingKeys.Date.rawValue: self.date.timeIntervalSince1970,
            CodingKeys.Name.rawValue: self.name,
            CodingKeys.Source.rawValue: self.source
        ]
    }
    
}
