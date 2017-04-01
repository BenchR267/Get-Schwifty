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
        
        self.textView = UITextView(frame: self.view.bounds)
        self.textView.backgroundColor = UIColor(colorLiteralRed: 31.0/255, green: 32.0/255, blue: 41.0/255, alpha: 1)
        
        self.textView.text = self.input
        self.textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(self.textView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let lexer = Lexer(input: self.input)
        let tokens = lexer.start()
        dump(tokens)
        self.textView.attributedText = attributedString(tokens: tokens)
    }

}

