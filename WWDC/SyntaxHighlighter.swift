//
//  SyntaxHighlighter.swift
//  WWDC
//
//  Created by Benjamin Herzog on 01.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

func attributedString(tokens: [Token]) -> NSAttributedString {
    let attr = NSMutableAttributedString(string: "")
    
    for t in tokens {
        let color: UIColor
        switch t.type {
        case .keyword:              color = keyword
        case .comment(_):           color = comments
        case .literal(.String(_)):  color = strings
        case .literal(.Integer(_)): color = numbers
        case .literal(.Double(_)):  color = numbers
        default:                    color = standard
        }
        var attributes: [String: NSObject] = [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: color
        ]
        if t.type == .illegal {
            attributes[NSStrikethroughStyleAttributeName] = 1 as NSNumber
            attributes[NSStrikethroughColorAttributeName] = UIColor.red
        }
        attr.append(NSAttributedString(string: t.raw, attributes: attributes))
    }
    
    return attr
}

extension UIColor {
    convenience init(r: Int, g: Int, b: Int, a: Double) {
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: CGFloat(a))
    }
}

private let font = UIFont.systemFont(ofSize: 14)

private let standard = UIColor(r: 225, g: 226, b: 231, a: 1)
private let keyword = UIColor(r: 225, g: 44, b: 160, a: 1)
private let comments = UIColor(r: 69, g: 187, b: 62, a: 1)
private let strings = UIColor(r: 211, g: 35, b: 46, a: 1)
private let numbers = UIColor(r: 20, g: 156, b: 146, a: 1)
