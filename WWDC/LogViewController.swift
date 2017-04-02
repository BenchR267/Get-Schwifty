//
//  LogViewController.swift
//  WWDC
//
//  Created by Benjamin Herzog on 02.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

public class LogViewController: UIViewController {
    
    private weak var textView: UITextView?
    
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
        (self.parent ?? self).navigationItem.rightBarButtonItems = []
        (self.parent ?? self).navigationItem.leftBarButtonItems = []
        (self.parent ?? self).title = "Log Output"
    }
    
    public func clear() {
        self.textView?.text = ""
    }
    
    public func write(_ text: String) {
        self.textView?.text.append(text + "\n")
    }
}
