//
//  ViewController.swift
//  WWDC
//
//  Created by Benjamin Herzog on 29.03.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    lazy var input: String = {
        guard let path = Bundle.main.path(forResource: "test", ofType: "txt") else {
            fatalError("Could not find test.txt in Bundle!")
        }
        
        return (try? String(contentsOfFile: path)) ?? ""
    }()
    
    var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let parser = Parser(input: self.input)
        do {
            let programm = try parser.parseProgram()
            dump(programm)
        } catch {
            print(">>>>>>", error)
        }
        
        
        
        
        return
        let insets = UIEdgeInsets(top: 20, left: 8, bottom: 0, right: 8)
        self.textView = UITextView(frame: UIEdgeInsetsInsetRect(self.view.bounds, insets))
        self.textView.autocapitalizationType = .none
        self.textView.autocorrectionType = .no
        self.textView.delegate = self
        self.textView.backgroundColor = UIColor(r: 31, g: 32, b: 41, a: 1)
        self.view.backgroundColor = self.textView.backgroundColor
        
        self.textView.text = self.input
        self.textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(self.textView)
        self.updateText(text: self.textView.text)
    }

}

extension ViewController: UITextViewDelegate {
    
    static let throttle: TimeInterval = 0.05
    
    func textViewDidChange(_ textView: UITextView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(updateText), with: textView.text, afterDelay: ViewController.throttle)
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
