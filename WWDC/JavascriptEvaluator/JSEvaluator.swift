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
    
    private var alerts = [(title: String, message: String)]()
    
    // needed for alerts - stored weak
    private weak var controller: UIViewController?
    private var outStream: (String) -> Void
    private init(controller: UIViewController, outStream: @escaping (String) -> Void, full: Bool) {
        self.controller = controller
        self.outStream = outStream
        
        if full {
            let consoleLog: @convention(block) () -> Void = {
                let args = JSContext.currentArguments().map { "\($0)" }.joined(separator: " ")
                self.outStream(args)
            }
            context.setObject(unsafeBitCast(consoleLog, to: AnyObject.self), forKeyedSubscript: "print" as (NSCopying & NSObjectProtocol)!)
            
            let alert: @convention(block) () -> Void = { [weak self] in
                let args = JSContext.currentArguments().map { "\($0)" }
                let title: String
                let message: String
                switch args.count {
                case 2:
                    title = args[0]
                    message = args[1]
                case 3..<Int.max:
                    title = args[0]
                    message = args[1..<args.count].joined(separator: " ")
                default:
                    title = ""
                    message = args.joined(separator: " ")
                }
                self?.alerts.append((title: title, message: message))
                self?.workAlerts()
            }
            context.setObject(unsafeBitCast(alert, to: AnyObject.self), forKeyedSubscript: "alert" as (NSCopying & NSObjectProtocol)!)
        }
    }
    
    private func workAlerts() {
        guard !(self.controller?.presentedViewController is UIAlertController),  !self.alerts.isEmpty else {
            return
        }
        let a = self.alerts.removeFirst()
        let c = UIAlertController(title: a.title, message: a.message, preferredStyle: .alert)
        c.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in self.workAlerts() }))
        self.controller?.present(c, animated: true)
    }
    
    public static func run(controller: UIViewController, outStream: @escaping (String) -> Void, full: Bool = true, script: String) {
        let evaluator = JSEvaluator(controller: controller, outStream: outStream, full: full)
        evaluator.context.evaluateScript(script)
    }
    
}
