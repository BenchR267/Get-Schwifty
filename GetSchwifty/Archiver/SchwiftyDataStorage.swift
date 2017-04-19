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
                .flatMap {
                    let fileURL = URL(fileURLWithPath: "\(path)\($0)")
                    let data = try Data(contentsOf: fileURL)
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    return Schwifty(json: json as? [String: Any] ?? [:])
                }
                .sorted(by: { $0.date > $1.date })
            
        } catch {
            return []
        }
    }
    
    func save(_ schwifty: Schwifty) {
        
        let json = schwifty.json
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            print("‼️ Could not save schwifty file…")
            return
        }
        
        let archiveURL = URL(fileURLWithPath: "\(path)\(schwifty.id)")
        try? data.write(to: archiveURL, options: .atomic)
    }
    
    func delete(_ schwifty: Schwifty) {
        let itemPath = path + "\(schwifty.id)"
        if self.fileManager.fileExists(atPath: itemPath) {
            try? self.fileManager.removeItem(atPath: itemPath)
        }
    }
    
}
