//
//  ViewController.swift
//  WWDC
//
//  Created by Benjamin Herzog on 29.03.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

public protocol SourceViewControllerDelegate: class {
    func sourceViewControllerWillEvaluate(start: @escaping () -> Void)
    func sourceViewControllerDidEvaluate()
}

public class SourceViewController: UIViewController {
    
    lazy var input: String = "// Welcome to the Playground in the Playground!\n// Feel free to write and run scripts written in Swift! 🚀\n\nfunc fib(n: Int) -> Int {\n\tif n == 0 || n == 1 {\n\t\treturn n\n\t}\n\treturn fib(n-1) + fib(n-2)\n}\nprint(fib(30))\n"
    
    var textView: UITextView!
    private let generator = Generator()
    
    public var outStream: (String) -> Void = { print($0) }
    public var clear: () -> Void = {}
    
    private var observer: NSObjectProtocol?
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .medium
        return df
    }()
    
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
        let run = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(evaluateHandler))
        self.navigationItem.rightBarButtonItem = run
        self.navigationItem.leftBarButtonItem = nil
        self.title = "Get Schwifty"
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.textView.contentInset = UIEdgeInsets(top: self.headerHeight, left: 0, bottom: 0, right: 0)
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
            
            let time = self.dateFormatter.string(from: Date())
            
            let block: () -> Void = {
                self.outStream("=========== " + self.dateFormatter.string(from: Date()) + " ===========")
                let bottom = Array(repeating: "=", count: time.characters.count + 24).joined()
                JSEvaluator.run(controller: self.topParent, outStream: self.outStream, full: full, script: js)
                self.outStream(bottom)
                self.delegate?.sourceViewControllerDidEvaluate()
            }
            
            if let delegate = self.delegate {
                delegate.sourceViewControllerWillEvaluate(start: block)
            } else {
                block()
            }
            
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