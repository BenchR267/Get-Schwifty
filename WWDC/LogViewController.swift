//
//  LogViewController.swift
//  WWDC
//
//  Created by Benjamin Herzog on 02.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

public protocol LogViewControllerDelegate: class {
    func logViewControllerDidPressBack()
}

public class LogViewController: UIViewController {
    
    private weak var textView: UITextView?
    
    public weak var delegate: LogViewControllerDelegate?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let textView = UITextView(frame: self.view.bounds)
        textView.font = font
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.backgroundColor = .black
        textView.textColor = .white
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.alwaysBounceVertical = true
        textView.isEditable = false
        textView.backgroundColor = UIColor(r: 31, g: 32, b: 41, a: 1)

        self.view.addSubview(textView)
        self.textView = textView
        self.view.backgroundColor = textView.backgroundColor
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.textView?.contentInset = UIEdgeInsets(top: self.headerHeight, left: 0, bottom: 0, right: 0)
        
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(back))
        let clearButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(clear))
        
        (self.parent ?? self).navigationItem.leftBarButtonItem = backButton
        (self.parent ?? self).navigationItem.rightBarButtonItem = clearButton
        (self.parent ?? self).title = "Log Output"
    }
    
    func back() {
        self.delegate?.logViewControllerDidPressBack()
    }
    
    func clear() {
        self.textView?.text = ""
    }
    
    public func write(_ text: String) {
        self.textView?.text.append(text + "\n")
        self.textView?.font = font
        
    }
}
