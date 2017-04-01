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
    
    private var alerts = [String]()
    
    // needed for alerts - stored weak
    private weak var controller: UIViewController?
    private init(controller: UIViewController, full: Bool) {
        self.controller = controller
        
        if full {
            let consoleLog: @convention(block) () -> Void = {
                let args = JSContext.currentArguments().map { "\($0)" }.joined(separator: " ")
                print(args, separator: " ", terminator: "\n")
            }
            context.setObject(unsafeBitCast(consoleLog, to: AnyObject.self), forKeyedSubscript: "print" as (NSCopying & NSObjectProtocol)!)
            
            let alert: @convention(block) () -> Void = { [weak self] in
                let args = JSContext.currentArguments().map { "\($0)" }.joined(separator: " ")
                self?.alerts.append(args)
                self?.workAlerts()
            }
            context.setObject(unsafeBitCast(alert, to: AnyObject.self), forKeyedSubscript: "alert" as (NSCopying & NSObjectProtocol)!)
        }
    }
    
    private func workAlerts() {
        guard !(self.controller?.presentedViewController is UIAlertController),  !self.alerts.isEmpty else {
            return
        }
        let c = UIAlertController(title: "Alert", message: self.alerts.removeFirst(), preferredStyle: .alert)
        c.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in self.workAlerts() }))
        self.controller?.present(c, animated: true)
    }
    
    public static func run(controller: UIViewController, full: Bool = true, script: String) {
        let evaluator = JSEvaluator(controller: controller, full: full)
        evaluator.context.evaluateScript(script)
    }
    
}
