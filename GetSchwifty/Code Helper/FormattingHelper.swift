//
//  FormattingHelper.swift
//  GetSchwifty
//
//  Created by Lennart Wisbar on 03.05.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

extension SourceViewController {
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        textView.insertAsCode(text)
        return false
    }
}

extension UITextView {
    // MARK: - Main code formatting function
    func insertAsCode(_ text: String) {
        guard let cursorPosition = selectedTextRange?.start else { return }
        var inputHasBeenModified = false
        
        switch text {
        case ":":
            // In a switch, set the indentation of a "case" or "default" to the same level as the switch
            guard let firstPartOfLine = lineFromStartToCursor,
                self.range(firstPartOfLine, contains: "case") || self.range(firstPartOfLine, contains: "default"),
                let lastSwitchPosition = positionAfterPrevious("switch") else { break }
            let caseIndentationLevel = currentIndentationLevel
            moveCursor(to: lastSwitchPosition)
            let switchIndentationLevel = currentIndentationLevel
            moveCursor(to: cursorPosition)
            indentCurrentLine(switchIndentationLevel - caseIndentationLevel)
        case "\n":
            // In any case of the return key being typed, open a new line and maintain indentation
            guard let firstPartOfLine = lineFromStartToCursor else { break }
            let previousCharacter = characterBefore(cursorPosition, ignoring: [" ", "\t"])
            let followingCharacter = characterAfter(cursorPosition)
            let indentationLevel = currentIndentationLevel
            newLine()
            indentCurrentLine(indentationLevel)
            inputHasBeenModified = true
            
            // Additional actions after open curly brace
            if previousCharacter == "{" {
                
                // Cursor between "{}"
                if followingCharacter == previousCharacter.counterpart {
                    newLine()
                    indentCurrentLine(indentationLevel)
                    moveCursor(-(indentationLevel+1))
                    indentCurrentLine()
                    break
                }
                
                // Indent one more unless we are in a switch
                if !self.range(firstPartOfLine, contains: "switch") { indentCurrentLine() }
                
                // More "{" than "}"
                if number(of: previousCharacter) - number(of: previousCharacter.counterpart) > 0 {
                    newLine()
                    indentCurrentLine(indentationLevel)
                    insertText("}")
                    moveCursor(-(indentationLevel+2))
                }
                
                // Indent next line after a "case ...:" or "default:"
            } else if previousCharacter == ":",
                self.range(firstPartOfLine, contains: "case") || self.range(firstPartOfLine, contains: "default") {
                indentCurrentLine()
            }
        case "(", "[":
            // Close brackets unless they already are
            if containsMore(of: text, than: text.counterpart) {
                insertText(text + text.counterpart)
                moveCursor(-1)
                inputHasBeenModified = true
            }
        case "}", ")", "]":
            // Step over closed brackets if typed unnecessarily
            if characterAfter(cursorPosition) == text
                && containsMore(of: text, than: text.counterpart) {
                moveCursor()
                inputHasBeenModified = true
                
                // Play warning if there are too many closed brackets
            } else if containsMore(of: text, than: text.counterpart) {
                // TODO: play warning sound
                print("too many closed brackets")
            }
        case "\"":
            let occurrences = number(of: text)
            
            // Only intervene if there is an even number of quotation marks
            guard (occurrences % 2) == 0 else { break }
            
            // Ignore closing of quotation marks if already closed
            if characterAfter(cursorPosition) == text {
                moveCursor()
                inputHasBeenModified = true
                
                // Else close opened quotation marks
            } else {
                insertText(text + text)
                moveCursor(-1)
                inputHasBeenModified = true
            }
        case "": // backspace
            backspace()
            inputHasBeenModified = true
        default:
            break
        }
        
        // If nothing has been modified: Just insert the text as normal
        if !inputHasBeenModified {
            insertText(text)
        }
    }
    
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
        guard times > 0 else { return }
        for _ in 1...times { insertText("\n") }
    }
    
    func backspace() {
        if selectedTextRange?.start == selectedTextRange?.end,
            let cursorPosition = selectedTextRange?.start,
            let oneStepBack = position(from: cursorPosition, offset: -1),
            let range = textRange(from: oneStepBack, to: cursorPosition) {
            replace(range, withText: "")
        } else {
            insertText("")
        }
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
