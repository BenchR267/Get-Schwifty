//
//  ViewController.swift
//  WWDC
//
//  Created by Benjamin Herzog on 29.03.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

public protocol SourceViewControllerDelegate: class {
    func sourceViewControllerDidEvaluate()
}

public class SourceViewController: UIViewController {
    
    lazy var input: String = "// Welcome to the Playground in the Playground!\n// My name is Benjamin Herzog.\n//\n// Since playgrounds are great to create interactive\n// programs I decided to create a playground.\n// You can run the code by pressing 'Run' at the top right \n// corner.\n//\n// This is only a subset of Swift containing functions (no\n// higher ones), variables, constants, while loops, if statements,\n// type inference and a light weight type system.\n\nvar i = 3\nwhile i > 0 {\n\talert(\"countdown\", i)\n\tprint(\"countdown…\" + i)\n\ti -= 1\n}\n\nlet company = \"Apple\"\nlet location = \"San Jose\"\nlet event = \"WWDC\"\nlet year = 2017\nlet awesome = true\n\nfunc greeting(company: String, location: String, event: String, year: Int) -> String {\n\treturn \"Welcome to \" + event + \" \" + year + \" by \" + company + \" in \" + location\n}\n\nif awesome {\n\talert(\"awesome\", greeting(company, location, event, year) + \"!!! 🚀\")\n}"
    
    var textView: UITextView!
    private let generator = Generator()
    
    public var outStream: (String) -> Void = { print($0) }
    public var clear: () -> Void = {}
    
    var observer: NSObjectProtocol?
    
    public weak var delegate: SourceViewControllerDelegate?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView = UITextView(frame: self.view.bounds)
        self.textView.autocapitalizationType = .none
        self.textView.autocorrectionType = .no
        self.textView.alwaysBounceVertical = true
        self.textView.keyboardDismissMode = .interactive
        self.textView.keyboardAppearance = .dark
        self.textView.delegate = self
        self.textView.backgroundColor = UIColor(r: 31, g: 32, b: 41, a: 1)
        self.textView.tintColor = UIColor(r: 237, g: 82, b: 63, a: 1)
        self.view.backgroundColor = self.textView.backgroundColor
        
        self.textView.text = self.input
        self.textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(self.textView)
        self.updateText(text: self.textView.text)
        
        self.observer = NotificationCenter.default.addObserver(forName: .UIKeyboardWillChangeFrame, object: nil, queue: .main) { [weak self] n in
            guard let `self` = self else { return }
            guard let endFrame = n.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            self.textView.contentInset = UIEdgeInsets(top: self.headerHeight, left: 0, bottom: self.view.bounds.size.height - endFrame.origin.y, right: 0)
        }
        self.textView.contentInset = UIEdgeInsets(top: self.headerHeight, left: 0, bottom: 0, right: 0)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let run = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(evaluateHandler))
        (self.parent ?? self).navigationItem.rightBarButtonItem = run
        (self.parent ?? self).navigationItem.leftBarButtonItem = nil
        (self.parent ?? self).title = "WWDC - Benjamin Herzog"
    }
    
    func clearHandler() {
        self.clear()
    }
    
    func evaluateHandler() {
        self.evaluate()
    }
    
    private func evaluate(full: Bool = true) {
        if full {
            self.textView.resignFirstResponder()
        }
        do {
            let parser = Parser(input: self.textView.text)
            let program = try parser.parseProgram()
            let js = self.generator.generate(program: program)
            JSEvaluator.run(controller: self.parent ?? self, outStream: self.outStream, full: full, script: js)
            self.delegate?.sourceViewControllerDidEvaluate()
        } catch let error as Parser.Error {
            if !full { return }
            let c = UIAlertController(title: "Error", message: "Sorry, there is an error in your sourcecode. Maybe this helps you tracking it down:\n\n\(error.string)", preferredStyle: .alert)
            c.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(c, animated: true)
        } catch {
            let c = UIAlertController(title: "Error", message: "Unexpected error occured.", preferredStyle: .alert)
            c.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(c, animated: true)
        }
    }
    
}

extension SourceViewController: UITextViewDelegate {
    
    static let throttle: TimeInterval = 0.05
    
    public func textViewDidChange(_ textView: UITextView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(updateText), with: textView.text, afterDelay: SourceViewController.throttle)
    }
    
    func updateText(text: String) {
        let lexer = Lexer(input: text)
        let tokens = lexer.start()
        let range = textView.selectedRange
        textView.isScrollEnabled = false
        textView.attributedText = attributedString(tokens: tokens)
        textView.isScrollEnabled = true
        textView.selectedRange = range
    }
    
}
