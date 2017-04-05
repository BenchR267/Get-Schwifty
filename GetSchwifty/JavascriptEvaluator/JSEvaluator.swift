//
//  JSEvaluator.swift
//  WWDC
//
//  Created by Benjamin Herzog on 01.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit
import JavaScriptCore

private let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.timeStyle = .medium
    return df
}()

public class JSEvaluator {
    
    private let context = JSContext()!
    
    private var alerts = [(title: String, message: String)]()
    
    // needed for alerts - stored weak
    private weak var controller: UIViewController?
    private var outStream: (String) -> Void
    init(controller: UIViewController, outStream: @escaping (String) -> Void) {
        self.controller = controller
        self.outStream = outStream
        
        let consoleLog: @convention(block) () -> Void = {
            let args = JSContext.currentArguments().map { "\($0)" }.joined(separator: " ")
            DispatchQueue.main.async {
                self.outStream(args)
            }
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
        
        let sleepHandler: @convention(block) () -> Void = {
            if let args = JSContext.currentArguments().first as? JSValue, args.isNumber {
                Thread.sleep(forTimeInterval: args.toDouble())
            } else {
                Thread.sleep(forTimeInterval: 1)
            }
        }
        context.setObject(unsafeBitCast(sleepHandler, to: AnyObject.self), forKeyedSubscript: "sleep" as (NSCopying & NSObjectProtocol)!)
    }
    
    private func workAlerts() {
        guard !(self.controller?.presentedViewController is UIAlertController),  !self.alerts.isEmpty else {
            return
        }
        let a = self.alerts.removeFirst()
        let c = UIAlertController(title: a.title, message: a.message, preferredStyle: .alert)
        c.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in self.workAlerts() }))
        DispatchQueue.main.async {
            self.controller?.present(c, animated: true)
        }
    }
    
    public func run(script: Program, done: @escaping () -> Void) {
        let time = dateFormatter.string(from: Date())
        self.outStream("=========== " + time + " ===========")
        DispatchQueue(label: "js").async {
            let generator = Generator()
            for s in script.scope.statements {
                self.context.evaluateScript(generator.generate(s))
            }
            DispatchQueue.main.async {
                let bottom = Array(repeating: "=", count: time.characters.count + 24).joined()
                self.outStream(bottom)
                done()
            }
        }
    }
    
}
