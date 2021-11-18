//
//  Completer.swift
//  GetSchwifty
//
//  Created by Lennart Wisbar on 03.05.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import Foundation

struct Completer {
    static func completedText(for input: String, in text: String, range: NSRange) -> (newText: String, newRange: NSRange) {
        guard
            let selection = text.stringRange(from: range),
            let scenario = Completer.scenario(for: input, in: text, range: range)
            else { return (text, range) }
        
        let line = text.lineRange(for: selection.lowerBound..<selection.lowerBound)
        let indentation = text.indentationLevel(of: line)
        
        var (insertion, cursorOffset) = completedInput(for: input, scenario: scenario, indentation: indentation)
        
        var newText = text.replacingCharacters(in: selection, with: insertion)
        
        // Change the indentation of the current line if needed
        // TODO: Refactor indentation correction into its own method?
        if scenario == .colonAfterCaseOrDefault,
            let switchIndentation = text.indentationLevelOfLast("switch", before: selection.lowerBound) {
            let newCursor = newText.index(selection.lowerBound, offsetBy: cursorOffset)
            let newLine = newText.lineRange(for: newCursor..<newCursor)
            newText = newText.settingIndentationLevel(of: newLine, to: switchIndentation)
            cursorOffset += (switchIndentation - indentation)
        }
        
        let newLocation = range.location + cursorOffset
        let newRange = NSMakeRange(newLocation, 0)
        
        return (newText: newText, newRange: newRange)
    }
}

private extension Completer {
    enum Scenario {
        case normal
        case newLine
        case newLineAfterCurlyBrace
        case newLineBetweenCurlyBraces
        case newLineAfterCurlyBraceAlreadyClosed
        case newLineAfterCurlyBraceAfterSwitch
        case newLineBetweenCurlyBracesAfterSwitch
        case newLineAfterCurlyBraceAlreadyClosedAfterSwitch
        case newLineAfterColonAfterCaseOrDefault
        case colonAfterCaseOrDefault
        case openRoundBracket
        case openSquareBracket
        case closedRoundBracketBeforeClosedBracket
        case closedSquareBracketBeforeClosedBracket
        case closedCurlyBraceBeforeClosedCurlyBrace
        case quotationMark
        case quotationMarkBeforeQuotationMark
    }
    
    static func completedInput(for input: String, scenario: Scenario, indentation: Int) -> (String, cursorOffset: Int) {
        var insertion = input
        var cursorOffset = input.utf16.count
        
        switch scenario {
        case .normal:
            insertion = input
            cursorOffset = insertion.utf16.count
        case .newLine:
            let completion = String.tabs(for: indentation)
            insertion = input + completion
            cursorOffset = insertion.utf16.count
        case .newLineAfterCurlyBrace:
            var completion = String.tabs(for: indentation + 1)
            completion += "\n"
            completion += String.tabs(for: indentation)
            completion += "}"
            insertion = input + completion
            cursorOffset = input.utf16.count + indentation + 1
        case .newLineBetweenCurlyBraces:
            var completion = String.tabs(for: indentation + 1)
            completion += "\n"
            completion += String.tabs(for: indentation)
            insertion = input + completion
            cursorOffset = input.utf16.count + indentation + 1
        case .newLineAfterCurlyBraceAlreadyClosed:
            let completion = String.tabs(for: indentation + 1)
            insertion = input + completion
            cursorOffset = insertion.utf16.count
        case .newLineAfterCurlyBraceAfterSwitch:
            var completion = String.tabs(for: indentation)
            completion += "\n"
            completion += String.tabs(for: indentation)
            completion += "}"
            insertion = input + completion
            cursorOffset = input.utf16.count + indentation
        case .newLineBetweenCurlyBracesAfterSwitch:
            var completion = String.tabs(for: indentation)
            completion += "\n"
            completion += String.tabs(for: indentation)
            insertion = input + completion
            cursorOffset = input.utf16.count + indentation
        case .newLineAfterCurlyBraceAlreadyClosedAfterSwitch:
            let completion = String.tabs(for: indentation)
            insertion = input + completion
            cursorOffset = insertion.utf16.count
        case .newLineAfterColonAfterCaseOrDefault:
            let completion = String.tabs(for: indentation + 1)
            insertion = input + completion
            cursorOffset = insertion.utf16.count
        case .colonAfterCaseOrDefault:
            insertion = input
            cursorOffset = insertion.utf16.count
        case .openRoundBracket:
            insertion = input + ")"
            cursorOffset = input.utf16.count
        case .openSquareBracket:
            insertion = input + "]"
            cursorOffset = input.utf16.count
        case .closedRoundBracketBeforeClosedBracket:
            insertion = ""
            cursorOffset = input.utf16.count
        case .closedSquareBracketBeforeClosedBracket:
            insertion = ""
            cursorOffset = input.utf16.count
        case .closedCurlyBraceBeforeClosedCurlyBrace:
            insertion = ""
            cursorOffset = input.utf16.count
        case .quotationMark:
            insertion = input + "\""
            cursorOffset = input.utf16.count
        case .quotationMarkBeforeQuotationMark:
            insertion = ""
            cursorOffset = input.utf16.count
        }
        
        return (insertion, cursorOffset: cursorOffset)
    }
    
    static func scenario(for input: String, in text: String, range: NSRange) -> Scenario? {
        guard let selection = text.stringRange(from: range)
            else { return nil }
        
        let previousCharacter = text.character(before: selection.lowerBound, ignoring: [" ", "\t"])
        let nextCharacter = text.character(at: selection.lowerBound)
        
        let lineRange = text.lineRange(for: selection.lowerBound..<selection.lowerBound)
        let line = text[lineRange]
        let distilledLine = line.components(separatedBy: .whitespacesAndNewlines).joined()
        let isValidSwitchLine: Bool = { return distilledLine.hasPrefix("switch") && distilledLine != "switch{" }()
        
        var scenario = Scenario.normal
        
        switch input {
        case "\n" where previousCharacter == "{" && nextCharacter == "}":
            if isValidSwitchLine {
                scenario = .newLineBetweenCurlyBracesAfterSwitch
            } else {
                scenario = .newLineBetweenCurlyBraces
            }
        case "\n" where previousCharacter == "{" && text.number(of: "}") >= text.number(of: "{"):
            if isValidSwitchLine {
                scenario = .newLineAfterCurlyBraceAlreadyClosedAfterSwitch
            } else {
                scenario = .newLineAfterCurlyBraceAlreadyClosed
            }
        case "\n" where previousCharacter == "{":
            if isValidSwitchLine {
                scenario = .newLineAfterCurlyBraceAfterSwitch
            } else {
                scenario = .newLineAfterCurlyBrace
            }
        case "\n" where (previousCharacter == ":") &&
            ((distilledLine.hasPrefix("case") && distilledLine != "case:") || distilledLine == "default:"):
            scenario = .newLineAfterColonAfterCaseOrDefault
        case "\n":
            scenario = .newLine
        case ":" where ((distilledLine.hasPrefix("case") && distilledLine != "case") || distilledLine == "default"):
            scenario = .colonAfterCaseOrDefault
        case "(" where text.number(of: "(") >= text.number(of: ")"):
            scenario = .openRoundBracket
        case "[" where text.number(of: "[") >= text.number(of: "]"):
            scenario = .openSquareBracket
        case ")" where nextCharacter == ")" && (text.number(of: "(") <= text.number(of: ")")):
            scenario = .closedRoundBracketBeforeClosedBracket
        case "]" where nextCharacter == "]" && (text.number(of: "[") <= text.number(of: "]")):
            scenario = .closedSquareBracketBeforeClosedBracket
        case "}" where nextCharacter == "}" && (text.number(of: "{") <= text.number(of: "}")):
            scenario = .closedSquareBracketBeforeClosedBracket
        case "\"" where nextCharacter == "\"" && (text.number(of: "\"") % 2 == 0):
            scenario = .closedSquareBracketBeforeClosedBracket
        case "\"" where text.number(of: "\"") % 2 == 0:
            scenario = .quotationMark
        default:
            break
        }
        
        return scenario
    }
}

private extension String {
    
    func stringRange(from range: NSRange) -> Range<String.Index>? {
        guard
            let utf16Start = utf16.index(utf16.startIndex, offsetBy: range.location, limitedBy: utf16.endIndex),
            let utf16End = utf16.index(utf16.startIndex, offsetBy: range.location + range.length, limitedBy: utf16.endIndex),
            let start = utf16Start.samePosition(in: self),
            let end = utf16End.samePosition(in: self)
            else { return nil }
        return start..<end
    }
    
    func range(ofClosest text: String, before position: String.Index) -> Range<String.Index>? {
        guard var startOfRange = self.index(position, offsetBy: -text.count, limitedBy: startIndex)
            else { return nil }
        var endOfRange = position
        
        while true {
            let range = startOfRange..<endOfRange
            let candidate = self[range]
            if candidate == text { return range }
            guard let newStart = self.index(startOfRange, offsetBy: -1, limitedBy: startIndex)
                else { return nil }
            startOfRange = newStart
            endOfRange = index(before: endOfRange)
        }
    }
    
    func range(ofClosest text: String, after position: String.Index) -> Range<String.Index>? {
        guard var endOfRange = self.index(position, offsetBy: text.count, limitedBy: endIndex)
            else { return nil }
        var startOfRange = position
        
        while true {
            let range = startOfRange..<endOfRange
            let candidate = self[range]
            if candidate == text { return range }
            guard let newEnd = self.index(endOfRange, offsetBy: 1, limitedBy: endIndex)
                else { return nil }
            endOfRange = newEnd
            startOfRange = index(after: startOfRange)
        }
    }
    
    func indentationLevel(of line: Range<String.Index>) -> Int {
        var level = 0
        var position = line.lowerBound
        
        while position != line.upperBound {
            let character = self[position]
            if character == "\t" { level += 1 }
            else { break }
            position = index(after: position)
        }
        return level
    }
    
    func indentationLevelOfLast(_ phrase: String, before position: String.Index) -> Int? {
        guard let range = range(ofClosest: phrase, before: position)
            else { return nil }
        let line = lineRange(for: range)
        return indentationLevel(of: line)
    }
    
    func removingIndentation(of line: Range<String.Index>) -> String {
        var newText = self
        let indentation = indentationLevel(of: line)
        let endOfTabs = index(line.lowerBound, offsetBy: indentation)
        newText.removeSubrange(line.lowerBound..<endOfTabs)
        return newText
    }
    
    func settingIndentationLevel(of line: Range<String.Index>, to level: Int) -> String {
        var newText = self.removingIndentation(of: line)
        let tabs = String.tabs(for: level)
        newText.insert(contentsOf: tabs, at: line.lowerBound)
        return newText
    }
    
    func character(at position: String.Index, ignoring: [Character] = []) -> Character? {
        var position = position
        
        while position < endIndex {
            if !ignoring.contains(self[position]) {
                return self[position]
            }
            position = index(after: position)
        }
        return nil
    }
    
    func character(before position: String.Index, ignoring: [Character] = []) -> Character? {
        var position = position
        
        while position > startIndex {
            position = index(before: position)
            if !ignoring.contains(self[position]) {
                return self[position]
            }
        }
        return nil
    }
    
    func number(of string: String, in range: Range<String.Index>) -> Int {
        let split = components(separatedBy: string)
        return split.count-1
    }
    
    func number(of string: String) -> Int {
        let range = startIndex..<endIndex
        return number(of: string, in: range)
    }
    
    static func tabs(for indentation: Int) -> String {
        var tabs = ""
        if indentation > 0 {
            for _ in 1...indentation {
                tabs += "\t"
            }
        }
        return tabs
    }
}
