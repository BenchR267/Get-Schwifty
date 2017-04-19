//
//  SchwiftyDataFetcher.swift
//  GetSchwifty
//
//  Created by Marius Landwehr on 19.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import Foundation

class SchwiftyDataStorage {
    
    private let fileManager = FileManager.default
    private lazy var path: String = {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentPath = paths.first
        return documentPath!.appending("/schwiftyProjects/")
    }()
    
    init() {
        
        var isDir = ObjCBool(booleanLiteral: false)
        if !fileManager.fileExists(atPath: path, isDirectory: &isDir) {
            try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    func all() -> [Schwifty] {
        
        do {
            
            let pathes = try fileManager.contentsOfDirectory(atPath: path)
            
            return try pathes
                .map {
                    let fileURL = URL(fileURLWithPath: "\(path)\($0)")
                    let data = try Data(contentsOf: fileURL)
                    let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
                    return unarchiver.decodeObject() as! Schwifty
                }
                .sorted(by: { $0.date > $1.date })
            
        } catch {
            return []
        }
    }
    
    func save(_ schwifty: Schwifty) {
        
        let data = NSMutableData()
        let keyedArchiver = NSKeyedArchiver(forWritingWith: data)
        keyedArchiver.encodeRootObject(schwifty)
        keyedArchiver.finishEncoding()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .full
        
        let archiveURL = URL(fileURLWithPath: "\(path)\(dateFormatter.string(from: schwifty.date))")
        try! data.write(to: archiveURL, options: .atomic)
    }
}
