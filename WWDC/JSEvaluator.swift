//
//  JSEvaluator.swift
//  WWDC
//
//  Created by Benjamin Herzog on 01.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit
import JavaScriptCore

public class JSEvaluator {
    
    private let context = JSContext()!
    
    // needed for alerts - stored weak
    private weak var controller: UIViewController?
    init(controller: UIViewController) {
        self.controller = controller
        
        let consoleLog: @convention(block) () -> Void = {
            let args = JSContext.currentArguments().map { "\($0)" }.joined(separator: " ")
            print(args, separator: " ", terminator: "\n")
        }
        context.setObject(unsafeBitCast(consoleLog, to: AnyObject.self), forKeyedSubscript: "print" as (NSCopying & NSObjectProtocol)!)
        
        let alert: @convention(block) () -> Void = { [weak self] in
            let args = JSContext.currentArguments().map { "\($0)" }.joined(separator: " ")
            let c = UIAlertController(title: "Alert", message: args, preferredStyle: .alert)
            c.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self?.controller?.present(c, animated: true)
        }
        context.setObject(unsafeBitCast(alert, to: AnyObject.self), forKeyedSubscript: "alert" as (NSCopying & NSObjectProtocol)!)
    }
    
    public func run(script: String) {
        self.context.evaluateScript(script)
    }
    
}
