//
//  LogViewController.swift
//  WWDC
//
//  Created by Benjamin Herzog on 02.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

protocol LogViewControllerDelegate: class {
    func logViewControllerDidPressBack()
    func logViewControllerDidPressStop()
}

class LogViewController: UIViewController {

    weak var delegate: LogViewControllerDelegate?

    private weak var textView: UITextView?
    private weak var stopButton: UIBarButtonItem?

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.didStop()

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

        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(back))
        let clearButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Clear"), style: .plain, target: self, action: #selector(clear))
        let stopButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Stop"), style: .plain, target: self, action: #selector(stop))
        self.stopButton = stopButton

        self.navigationItem.rightBarButtonItem = backButton
        self.navigationItem.leftBarButtonItems = [clearButton, stopButton]
        self.title = "Log Output"
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.textView?.contentInset = UIEdgeInsets(top: self.headerHeight, left: 0, bottom: 0, right: 0)
    }

    func back() {
        self.delegate?.logViewControllerDidPressBack()
    }

    func clear() {
        self.textView?.text = ""
    }

    func stop() {
        self.delegate?.logViewControllerDidPressStop()
    }

    public func didStart() {
        self.stopButton?.isEnabled = true
    }

    public func didStop() {
        self.stopButton?.isEnabled = false
    }

    public func write(_ text: String) {
        self.textView?.text.append(text + "\n")
        self.textView?.font = font
    }
}
