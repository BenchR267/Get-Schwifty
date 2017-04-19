//
//  File.swift
//  GetSchwifty
//
//  Created by Marius Landwehr on 19.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import Foundation

class Schwifty: NSObject, NSCoding {
    
    private enum CodingKeys: String {
        case Sources
        case Date
    }
    
    var sources: String
    private(set) var date: Date
    
    required init?(coder aDecoder: NSCoder) {
        sources = aDecoder.decodeObject(forKey: CodingKeys.Sources.rawValue) as! String
        date = aDecoder.decodeObject(forKey: CodingKeys.Date.rawValue) as! Date
        super.init()
    }
    
    init(with sources: String) {
        self.sources = sources
        date = Date()
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(sources, forKey: CodingKeys.Sources.rawValue)
        aCoder.encode(date, forKey: CodingKeys.Date.rawValue)
    }
}
