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
    
    lazy var input: String = {
        guard let path = Bundle.main.path(forResource: "start_script", ofType: "txt") else {
            fatalError("Could not open start script!")
        }
        return (try? String(contentsOfFile: path)) ?? ""
    }()
    
    var textView: UITextView!
    private let generator = Generator()
    
    public var outStream: (String) -> Void = { print($0) }
    
    private var observer: NSObjectProtocol?
    
    public weak var delegate: SourceViewControllerDelegate?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView = UITextView(frame: self.view.bounds)
        self.textView.autocapitalizationType = .none
        self.textView.autocorrectionType = .no
        self.textView.spellCheckingType = .no
        if #available(iOS 11.0, *) {
            self.textView.smartQuotesType = .no
            self.textView.smartDashesType = .no
            self.textView.smartInsertDeleteType = .no
        }
        
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
        
        self.observer = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { [weak self] n in
            guard let `self` = self else { return }
            guard let endFrame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            let intersection = self.view.frame.intersection(endFrame)
            
            self.textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.view.bounds.size.height - intersection.origin.y, right: 0)
        }
        let run = UIBarButtonItem(image: #imageLiteral(resourceName: "Play"), style: .plain, target: self, action: #selector(evaluateHandler))
        let info = UIBarButtonItem(image: #imageLiteral(resourceName: "Info"), style: .plain, target: self, action: #selector(showInfo))
        self.navigationItem.rightBarButtonItem = run
        self.navigationItem.leftBarButtonItem = info
        self.title = "Get Schwifty"
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.textView.contentInset = UIEdgeInsets.zero
    }
    
    @objc func showInfo() {
        let info = InfoViewController().wrapInNavigationController()
        self.present(info, animated: true)
    }
    
    @objc func evaluateHandler() {
        self.evaluate()
    }
    
    var currentEvaluator: JSEvaluator?
    @objc func stop() {
        self.currentEvaluator?.stop()
        self.currentEvaluator = nil
    }
    
    private func evaluate() {
        self.textView.resignFirstResponder()
        do {
            let lexer = Lexer(input: self.textView.text)
            let tokens = lexer.start()
            let parser = Parser(tokens: tokens)
            let program = try parser.parseProgram()
            let evaluator = JSEvaluator(controller: self.topParent, outStream: self.outStream)
            self.currentEvaluator = evaluator
            
            let block: () -> Void = {
                evaluator.run(script: program) {
                    self.delegate?.sourceViewControllerDidEvaluate()
                    self.currentEvaluator = nil
                }
            }
            
            if let delegate = self.delegate {
                delegate.sourceViewControllerWillEvaluate(start: block)
            } else {
                block()
            }
            
        } catch let error as Parser.Error {
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
    
//    Currently broken due to changes in Completer because of Swift 4. When fixed, this needs to be commented in. Also: don't set the .text property of the textView. Instead call updateText with the new text to let it set the attributedText instead.
//    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        let (newText, newRange) = Completer.completedText(for: text, in: textView.text, range: range)
//        textView.text = newText
//        textView.selectedRange = newRange
//        textViewDidChange(textView)
//        return false
//    }
    
    public func textViewDidChange(_ textView: UITextView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(updateText), with: textView.text, afterDelay: SourceViewController.throttle)
    }
    
    @objc func updateText(text: String) {
        let lexer = Lexer(input: text)
        let tokens = lexer.start()
        let range = textView.selectedRange
        textView.isScrollEnabled = false
        textView.attributedText = attributedString(tokens: tokens)
        textView.isScrollEnabled = true
        textView.selectedRange = range
    }
    
}
