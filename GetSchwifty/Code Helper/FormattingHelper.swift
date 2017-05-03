//
//  TypingHelper.swift
//  GetSchwifty
//
//  Created by Lennart Wisbar on 03.05.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

extension SourceViewController {
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let cursorPosition = textView.selectedTextRange?.start else { return true }
        var inputHasBeenModified = false
        
        switch text {
        case ":":
            guard let firstPartOfLine = textView.lineFromStartToCursor,
                textView.range(firstPartOfLine, contains: "case") || textView.range(firstPartOfLine, contains: "default"),
                let lastSwitchPosition = textView.positionAfterPrevious("switch") else { return true }
            let caseIndentationLevel = textView.currentIndentationLevel
            textView.moveCursor(to: lastSwitchPosition)
            let switchIndentationLevel = textView.currentIndentationLevel
            textView.moveCursor(to: cursorPosition)
            textView.indentCurrentLine(switchIndentationLevel - caseIndentationLevel)
        case "\n":
            guard let firstPartOfLine = textView.lineFromStartToCursor else { return true }
            let previousCharacter = textView.characterBefore(cursorPosition, ignoring: [" ", "\t"])
            let followingCharacter = textView.characterAfter(cursorPosition)
            let indentationLevel = textView.currentIndentationLevel
            textView.newLine()
            textView.indentCurrentLine(indentationLevel)
            inputHasBeenModified = true
            if previousCharacter == "{" {
                if followingCharacter == previousCharacter.counterpart {
                    textView.newLine()
                    textView.indentCurrentLine(indentationLevel)
                    textView.moveCursor(-(indentationLevel+1))
                    textView.indentCurrentLine()
                    break
                }
                if !textView.range(firstPartOfLine, contains: "switch") { textView.indentCurrentLine() }
                if textView.number(of: previousCharacter) - textView.number(of: previousCharacter.counterpart) > 0 {
                    textView.newLine()
                    textView.indentCurrentLine(indentationLevel)
                    textView.insertText("}")
                    textView.moveCursor(-(indentationLevel+2))
                }
            } else if previousCharacter == ":",
                textView.range(firstPartOfLine, contains: "case") || textView.range(firstPartOfLine, contains: "default") {
                textView.indentCurrentLine()
            }
        case "(", "[":
            if textView.containsMore(of: text, than: text.counterpart) {
                textView.insertText(text + text.counterpart)
                textView.moveCursor(-1)
                inputHasBeenModified = true
            }
        case "}", ")", "]":
            if textView.characterAfter(cursorPosition) == text
                && textView.containsMore(of: text, than: text.counterpart) {
                textView.moveCursor()
                inputHasBeenModified = true
            } else if textView.containsMore(of: text, than: text.counterpart) {
                // TODO: play warning sound
                print("too many closed brackets")
            }
        case "\"":
            let occurrences = textView.number(of: text)
            guard (occurrences % 2) == 0 else { return true }
            if textView.characterAfter(cursorPosition) == text {
                textView.moveCursor()
                inputHasBeenModified = true
            } else {
                textView.insertText(text + text)
                textView.moveCursor(-1)
                inputHasBeenModified = true
            }
        default:
            return true
        }

        return !inputHasBeenModified
    }
}

private extension UITextView {
    // MARK: - INFORMATION
    // MARK: About the current line
    var currentLine: UITextRange? {
        let newLine = "\n"
        let beginning = positionAfterPrevious(newLine) ?? beginningOfDocument
        let end = positionBeforeNext(newLine) ?? endOfDocument
        return textRange(from: beginning, to: end)
    }
    
    var lineFromStartToCursor: UITextRange? {
        guard let start = currentLine?.start,
            let cursorPosition = selectedTextRange?.start else { return nil }
        return textRange(from: start, to: cursorPosition)
    }
    
    var currentIndentationLevel: Int {
        guard let startOfLine = currentLine?.start else { return 0 }
        var offset = 0
        var indentationLevel = 0
        var nextCharacter = ""
        
        while true {
            guard let currentPosition = self.position(from: startOfLine, offset: offset) else { break }
            nextCharacter = characterAfter(currentPosition)
            if nextCharacter == "\t" { indentationLevel += 1; offset += 1 }
            else { break }
        }
        
        return indentationLevel
    }
    
    // MARK: Looking up characters at certain positions
    func characterBefore(_ position: UITextPosition, ignoring: [String] = []) -> String {
        guard let range = characterRange(byExtending: position, in: .left),
            let character = text(in: range) else { return "" }
        
        var offset = -1
        var nextCharacter = character
        while ignoring.contains(nextCharacter) {
            guard let nextPosition = self.position(from: position, offset: offset),
                let nextRange = characterRange(byExtending: nextPosition, in: .left),
                let character = text(in: nextRange) else { return "" }
            nextCharacter = character
            offset -= 1
        }
        return nextCharacter
    }
    
    func characterAfter(_ position: UITextPosition, ignoring: [String] = []) -> String {
        guard let range = characterRange(byExtending: position, in: .right),
            let character = text(in: range) else { return "" }
        
        var offset = 1
        var nextCharacter = character
        while ignoring.contains(nextCharacter) {
            guard let nextPosition = self.position(from: position, offset: offset),
                let nextRange = characterRange(byExtending: nextPosition, in: .left),
                let character = text(in: nextRange) else { return "" }
            nextCharacter = character
            offset += 1
        }
        return nextCharacter
    }
    
    // MARK: Finding nearby strings
    func positionAfterPrevious(_ string: String) -> UITextPosition? {
        guard var endOfRange = selectedTextRange?.start,
            var startOfRange = position(from: endOfRange, offset: -string.characters.count) else { return nil }
        while true {
            guard let range = textRange(from: startOfRange, to: endOfRange) else { return nil }
            if text(in: range) == string {
                return range.end
            }
            guard let newStart = position(from: startOfRange, offset: -1),
                let newEnd = position(from: endOfRange, offset: -1) else { return nil }
            startOfRange = newStart
            endOfRange = newEnd
        }
    }
    
    func positionBeforeNext(_ string: String) -> UITextPosition? {
        guard var startOfRange = selectedTextRange?.start,
            var endOfRange = position(from: startOfRange, offset: string.characters.count) else { return nil }
        while true {
            guard let range = textRange(from: startOfRange, to: endOfRange) else { return nil }
            if text(in: range) == string {
                return range.start
            }
            guard let newStart = position(from: startOfRange, offset: 1),
                let newEnd = position(from: endOfRange, offset: 1) else { return nil }
            startOfRange = newStart
            endOfRange = newEnd
        }
    }
    
    // MARK: Looking for occurrences of certain strings
    func number(of string: String) -> Int {
        guard let wholeDocument = textRange(from: beginningOfDocument, to: endOfDocument) else { return 0 }
        return number(of: string, in: wholeDocument)
    }
    
    func number(of string: String, in range: UITextRange) -> Int {
        guard let text = text(in: range) else { return 0 }
        let split = text.components(separatedBy: string)
        return split.count-1
    }
    
    func containsMore(of string1: String, than string2: String) -> Bool {
        return number(of: string1) - number(of: string2) >= 0
    }
    
    func range(_ range: UITextRange, contains string: String) -> Bool {
        return (number(of: string, in: range)) > 0
    }
    
    // MARK: - ACTIONS
    func newLine(_ times: UInt = 1) {
        for _ in 1...times { insertText("\n") }
    }
    
    func indentCurrentLine(_ steps: Int = 1) {
        guard let originalCursorPosition = selectedTextRange?.start,
            let beginningOfLine = currentLine?.start else { return }
        if steps > 0 {
            moveCursor(to: beginningOfLine)
            for _ in 1...steps { insertText("\t") }
            moveCursor(to: originalCursorPosition)
            moveCursor(steps)
        } else if (steps < 0) && (currentIndentationLevel > 0) {
            let surplusTabsCount = min(-steps, currentIndentationLevel)
            guard let endOfSurplusTabs = position(from: beginningOfLine, offset: surplusTabsCount),
                let range = textRange(from: beginningOfLine, to: endOfSurplusTabs),
                let newCursorPosition = position(from: originalCursorPosition, offset: -surplusTabsCount) else { return }
            replace(range, withText: "")
            moveCursor(to: newCursorPosition)
        }
    }
    
    func moveCursor(_ offset: Int = 1) {
        guard let oldCursorPosition = selectedTextRange?.start,
            let newCursorPosition = self.position(from: oldCursorPosition, offset: offset) else { return }
        selectedTextRange = textRange(from: newCursorPosition, to: newCursorPosition)
    }
    
    func moveCursor(to position: UITextPosition) {
        selectedTextRange = textRange(from: position, to: position)
    }
}

private extension String {
    var counterpart: String {
        switch self {
        case "(": return ")"
        case ")": return "("
        case "[": return "]"
        case "]": return "["
        case "{": return "}"
        case "}": return "{"
        default: return ""
        }
    }
}
