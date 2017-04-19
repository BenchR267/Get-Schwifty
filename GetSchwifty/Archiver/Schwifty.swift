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
        case Date, Name, Source, Temporary
    }
    
    // MARK: - API
    var source: String
    var name: String
    private(set) var date: Date
    var temporary: Bool
    var id: Double {
        return self.date.timeIntervalSince1970
    }
    
    init(source: String) {
        self.source = source
        let date = Date()
        self.date = date
        self.name = dateFormatter.string(from: date)
        self.temporary = true
    }
    
    // MARK: - Serialization
    
    init?(json: [String: Any]) {
        guard
            let date = json[CodingKeys.Date.rawValue] as? TimeInterval,
            let name = json[CodingKeys.Name.rawValue] as? String,
            let source = json[CodingKeys.Source.rawValue] as? String,
            let temporary = json[CodingKeys.Temporary.rawValue] as? Bool
        else {
            return nil
        }
        
        self.date = Date(timeIntervalSince1970: date)
        self.name = name
        self.source = source
        self.temporary = temporary
    }
    
    var json: [String: Any] {
        return [
            CodingKeys.Date.rawValue: self.date.timeIntervalSince1970,
            CodingKeys.Name.rawValue: self.name,
            CodingKeys.Source.rawValue: self.source,
            CodingKeys.Temporary.rawValue: self.temporary
        ]
    }
    
}
