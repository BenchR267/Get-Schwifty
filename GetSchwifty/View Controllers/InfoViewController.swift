//
//  InfoViewController.swift
//  GetSchwifty
//
//  Created by Benjamin Herzog on 06.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {
    
    private weak var textView: UITextView?
    
    override var modalPresentationStyle: UIModalPresentationStyle {
        get{
            return .formSheet
        }
        set {}
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let textView = UITextView(frame: self.view.bounds)
        textView.font = font
        textView.dataDetectorTypes = .link
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
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close))
        
        self.navigationItem.rightBarButtonItem = closeButton
        self.title = "Info"
        
        guard let path = Bundle.main.path(forResource: "info", ofType: "txt") else {
            return
        }
        textView.text = try? String(contentsOfFile: path)
    }
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
}
