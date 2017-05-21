//
//  FormattingHelperTests.swift
//  GetSchwifty
//
//  Created by Lennart Wisbar on 17.05.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

//  MARK: Test Naming Rule
//  test_Action_Expectation(_Condition)

import XCTest
@testable import Get_Schwifty

class FormattingHelperTests: XCTestCase {
    
    let textView = UITextView()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Helper Section
    var cursorOffsetFromEnd: Int {
        get {
            let cursorPosition = textView.selectedTextRange?.start
            XCTAssertNotNil(cursorPosition)
            return -textView.offset(from: cursorPosition!, to: textView.endOfDocument)
        }
        set {
            let position = textView.position(from: textView.endOfDocument, offset: newValue)
            XCTAssertNotNil(position)
            let range = textView.textRange(from: position!, to: position!)
            textView.selectedTextRange = range
        }
    }
    
    // MARK: - Normal Characters
    func test_NormalCharacters_NotAffected() {
        textView.text = "test"
        cursorOffsetFromEnd = -1    // Before the "t"
        textView.insertAsCode("a")
        
        XCTAssertEqual(textView.text, "tesat")     // "a" after "tes"
        XCTAssertEqual(cursorOffsetFromEnd, -1)     // after the typed "a"
    }
    
    // MARK: - Paste
    func test_Paste() {
        textView.text = "test"
        cursorOffsetFromEnd = -1    // Before the "t"
        textView.insertAsCode("abc")
        
        XCTAssertEqual(textView.text, "tesabct")     // "abc" after "tes"
        XCTAssertEqual(cursorOffsetFromEnd, -1)     // after the pasted "abc"
    }
    
    func test_PasteOverSelection() {    // Should also cover typing something while text is selected
        textView.text = "paste test"
        let end = textView.endOfDocument
        let start = textView.position(from: end, offset: -4)
        XCTAssertNotNil(start)
        let range = textView.textRange(from: start!, to: end)   // "test"
        textView.selectedTextRange = range
        textView.insertAsCode("abc")
        
        XCTAssertEqual(textView.text, "paste abc")     // Replaced "test" with "abc"
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    // MARK: - Backspace
    func test_BackspaceOneCharacter() {
        textView.text = "test"
        cursorOffsetFromEnd = 0
        textView.insertAsCode("")
        
        XCTAssertEqual(textView.text, "tes")    // Deleted last character
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    func test_BackspaceSelection() {    // Should also cover cut actions
        textView.text = "backspace selection test"
        let end = textView.endOfDocument
        let start = textView.position(from: end, offset: -4)
        XCTAssertNotNil(start)
        let range = textView.textRange(from: start!, to: end)   // "test"
        textView.selectedTextRange = range
        textView.insertAsCode("")
        
        XCTAssertEqual(textView.text, "backspace selection ")   // Deleted "test"
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    // MARK: - Colon
    func test_ColonAfterCase_AdoptsSwitchIndentation() {
        textView.text =
			"\t\tswitch test {" +
            "\n\t\t\tcase" +
			"\n\t\t}"
        cursorOffsetFromEnd = -4    // After the open curly brace
        textView.insertAsCode(":")
        
        XCTAssertEqual(textView.text,
			"\t\tswitch test {" +
			"\n\t\tcase:" +     // Colon after "case", one tab removed
            "\n\t\t}")
        XCTAssertEqual(cursorOffsetFromEnd, -4) // after the typed colon
    }
    
    func test_ColonAfterDefault_AdoptsSwitchIndentation() {
        textView.text =
			"\t\tswitch test {" +
            "\n\t\t\tdefault" +
			"\n\t\t}"
        cursorOffsetFromEnd = -4    // After the open curly brace
        textView.insertAsCode(":")
        
        XCTAssertEqual(textView.text,
			"\t\tswitch test {" +
			"\n\t\tdefault:" +     // Colon after "default", one tab removed
            "\n\t\t}")
        XCTAssertEqual(cursorOffsetFromEnd, -4) // After the typed colon
    }
    
    func test_ColonAfterCase_TreatedNormally_IfNoSwitch() {
        textView.text = "\t\t\tcase"
        cursorOffsetFromEnd = 0
        textView.insertAsCode(":")
        
        XCTAssertEqual(textView.text, "\t\t\tcase:")    // No tabs removed
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    func test_Colon_TreatedNormally_IfNoCaseOrDefault() {
        textView.text = "\t\t\tnormalText"
        cursorOffsetFromEnd = 0
        textView.insertAsCode(":")
        
        XCTAssertEqual(textView.text, "\t\t\tnormalText:")    // No tabs removed
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    // MARK: - Return Key After Normal Character
    func test_ReturnKeyAfterNormalCharacter_MaintainsIndentation() {
        textView.text = "\t\tnormalText"
        cursorOffsetFromEnd = 0
        textView.insertAsCode("\n")
        
        XCTAssertEqual(textView.text,
			"\t\tnormalText" +
            "\n\t\t")     // Indentation level maintained
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    // MARK: - Return Key After Curly Brace
    func test_ReturnKeyAfterCurlyBrace_IndentsNextLineAndClosesBrace() {
        textView.text = "\t\ttest {"
        cursorOffsetFromEnd = 0
        textView.insertAsCode("\n")
        
        XCTAssertEqual(textView.text,
			"\t\ttest {" +
			"\n\t\t\t" +    // Indentation level maintained
            "\n\t\t}")     // Closed curly brace added
        XCTAssertEqual(cursorOffsetFromEnd, -4) // End of the middle line
    }
    
    func test_ReturnKeyBetweenCurlyBraces_UsesExistingBrace() {
        textView.text = "\t\ttest {}"
        cursorOffsetFromEnd = -1    // Between the {}
        textView.insertAsCode("\n")
        
        XCTAssertEqual(textView.text,
			"\t\ttest {" +
			"\n\t\t\t" +    // Indentation level maintained
            "\n\t\t}")      // No curly brace added
        XCTAssertEqual(cursorOffsetFromEnd, -4) // End of the middle line
    }
    
    func test_ReturnKeyAfterCurlyBrace_DoesNotAddAnotherBrace_IfTooManyClosedBraces() {
        textView.text =
			"test {" +
			"\nanother line }"
        cursorOffsetFromEnd = -15   // After the open curly brace
        textView.insertAsCode("\n")
        
        XCTAssertEqual(textView.text,
			"test {" +
			"\n\t" +    // Indentation works as normal after "{"
            "\nanother line }") // No extra "}" added
        XCTAssertEqual(cursorOffsetFromEnd, -15)    // End of the middle line
    }
    
    func test_ReturnKeyAfterSwitchWithCurlyBrace_MaintainsIndentationAndClosesBrace() {
        textView.text = "\t\tswitch test {"
        cursorOffsetFromEnd = 0
        textView.insertAsCode("\n")
        
        XCTAssertEqual(textView.text,
			"\t\tswitch test {" +
			"\n\t\t" +    // Indentation level maintained
            "\n\t\t}")     // Closed curly brace added
        XCTAssertEqual(cursorOffsetFromEnd, -4) // End of the middle line
    }
    
    // MARK: - Return Key after "case"
    func test_ReturnKeyAfterCaseWithColon_IndentsNextLine() {
        textView.text = "\t\tcase test:"
        cursorOffsetFromEnd = 0
        textView.insertAsCode("\n")
        
        XCTAssertEqual(textView.text,
			"\t\tcase test:" +
            "\n\t\t\t")     // Indentation level raised
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    func test_ReturnKeyAfterCaseWithColonAndSpaces_IndentsNextLine() {
        textView.text = "\t\tcase test:   "
        cursorOffsetFromEnd = 0
        textView.insertAsCode("\n")
        
        XCTAssertEqual(textView.text,
			"\t\tcase test:   " +
            "\n\t\t\t")     // Indentation level raised
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    func test_ReturnKeyAfterCaseWithoutColon_DoesNotIndentNextLine() {
        textView.text = "\t\tcase test"
        cursorOffsetFromEnd = 0
        textView.insertAsCode("\n")
        
        XCTAssertEqual(textView.text,
			"\t\tcase test" +
            "\n\t\t")     // Indentation level maintained
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    func test_ReturnKeyAfterCaseWithTextAfterColon_DoesNotIndentNextLine() {
        textView.text = "\t\tcase test: text"
        cursorOffsetFromEnd = 0
        textView.insertAsCode("\n")
        
        XCTAssertEqual(textView.text,
			"\t\tcase test: text" +
            "\n\t\t")     // Indentation level maintained
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    // MARK: - Return Key After "default"
    func test_ReturnKeyAfterDefaultWithColon_IndentsNextLine() {
        textView.text = "\t\tdefault:"
        cursorOffsetFromEnd = 0
        textView.insertAsCode("\n")
        
        XCTAssertEqual(textView.text,
			"\t\tdefault:" +
            "\n\t\t\t")     // Indentation level raised
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    func test_ReturnKeyAfterDefaultWithColonAndSpaces_IndentsNextLine() {
        textView.text = "\t\tdefault:   "
        cursorOffsetFromEnd = 0
        textView.insertAsCode("\n")
        
        XCTAssertEqual(textView.text,
			"\t\tdefault:   " +
            "\n\t\t\t")     // Indentation level raised
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    func test_ReturnKeyAfterDefaultWithoutColon_DoesNotIndentNextLine() {
        textView.text = "\t\tdefault"
        cursorOffsetFromEnd = 0
        textView.insertAsCode("\n")
        
        XCTAssertEqual(textView.text,
			"\t\tdefault" +
            "\n\t\t")     // Indentation level maintained
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    func test_ReturnKeyAfterDefaultWithTextAfterColon_DoesNotIndentNextLine() {
        textView.text = "\t\tdefault: text"
        cursorOffsetFromEnd = 0
        textView.insertAsCode("\n")
        
        XCTAssertEqual(textView.text,
			"\t\tdefault: text" +
            "\n\t\t")     // Indentation level maintained
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    // MARK: - Open Brackets
    func test_openRoundBracket_ProducesClosedBracket() {
        textView.text = "test"
        cursorOffsetFromEnd = 0
        textView.insertAsCode("(")
        
        XCTAssertEqual(textView.text, "test()") // Bracket closed
        XCTAssertEqual(cursorOffsetFromEnd, -1) // Between the brackets
    }
    
    func test_openSquareBracket_ProducesClosedBracket() {
        textView.text = "test"
        cursorOffsetFromEnd = 0
        textView.insertAsCode("[")
        
        XCTAssertEqual(textView.text, "test[]") // Bracket closed
        XCTAssertEqual(cursorOffsetFromEnd, -1) // Between the brackets
    }
    
    func test_openRoundBracket_DoesNotProduceClosedBracket_IfTooManyClosedBrackets() {
        textView.text = "bracket test)"
        cursorOffsetFromEnd = -5    // Before "test"
        textView.insertAsCode("(")
        
        XCTAssertEqual(textView.text, "bracket (test)") // No additional bracket
        XCTAssertEqual(cursorOffsetFromEnd, -5) // After the open bracket
    }
    
    func test_openSquareBracket_DoesNotProduceClosedBracket_IfTooManyClosedBrackets() {
        textView.text = "bracket test]"
        cursorOffsetFromEnd = -5    // Before "test"
        textView.insertAsCode("[")
        
        XCTAssertEqual(textView.text, "bracket [test]") // No additional bracket
        XCTAssertEqual(cursorOffsetFromEnd, -5) // After the open bracket
    }
    
    // MARK: - Closed Round Brackets
    func test_closedRoundBracketAfterNormalCharacter_TreatedNormally() {
        textView.text = "bracket (test"
        cursorOffsetFromEnd = 0
        textView.insertAsCode(")")
        
        XCTAssertEqual(textView.text, "bracket (test)") // Normal behavior
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    func test_closedRoundBracketBeforeClosedRoundBracket_StepsOver() {
        textView.text = "bracket (test)"
        cursorOffsetFromEnd = -1
        textView.insertAsCode(")")
        
        XCTAssertEqual(textView.text, "bracket (test)") // No additional bracket
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    func test_closedRoundBracketBeforeClosedRoundBracket_TreatedNormally_IfTooManyOpenBrackets() {
        textView.text = "(bracket (test)"
        cursorOffsetFromEnd = -1
        textView.insertAsCode(")")
        
        XCTAssertEqual(textView.text, "(bracket (test))") // Normal behavior
        XCTAssertEqual(cursorOffsetFromEnd, -1)
    }
    
    // TODO: Play warning sound when too many closed round brackets in the document
    
    // MARK: - Closed Square Brackets
    func test_closedSquareBracketAfterNormalCharacter_TreatedNormally() {
        textView.text = "bracket [test"
        cursorOffsetFromEnd = 0
        textView.insertAsCode("]")
        
        XCTAssertEqual(textView.text, "bracket [test]") // Normal behavior
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    func test_closedSquareBracketBeforeClosedSquareBracket_StepsOver() {
        textView.text = "bracket [test]"
        cursorOffsetFromEnd = -1
        textView.insertAsCode("]")
        
        XCTAssertEqual(textView.text, "bracket [test]") // No additional bracket
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    func test_closedSquareBracketBeforeClosedSquareBracket_TreatedNormally_IfTooManyOpenBrackets() {
        textView.text = "[bracket [test]"
        cursorOffsetFromEnd = -1
        textView.insertAsCode("]")
        
        XCTAssertEqual(textView.text, "[bracket [test]]") // Normal behavior
        XCTAssertEqual(cursorOffsetFromEnd, -1)
    }
    
    // TODO: Play warning sound when too many closed square brackets in the document
    
    // MARK: - Closed Curly Braces
    func test_closedCurlyBraceAfterNormalCharacter_TreatedNormally() {
        textView.text = "bracket {test"
        cursorOffsetFromEnd = 0
        textView.insertAsCode("}")
        
        XCTAssertEqual(textView.text, "bracket {test}") // Normal behavior
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    func test_closedCurlyBraceBeforeClosedCurlyBrace_StepsOver() {
        textView.text = "bracket {test}"
        cursorOffsetFromEnd = -1
        textView.insertAsCode("}")
        
        XCTAssertEqual(textView.text, "bracket {test}") // No additional bracket
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    func test_closedCurlyBraceBeforeClosedCurlyBrace_TreatedNormally_IfTooManyOpenBraces() {
        textView.text = "{bracket {test}"
        cursorOffsetFromEnd = -1
        textView.insertAsCode("}")
        
        XCTAssertEqual(textView.text, "{bracket {test}}") // Normal behavior
        XCTAssertEqual(cursorOffsetFromEnd, -1)
    }
    
    // TODO: Play warning sound when too many closed curly braces in the document
    
    // MARK: - Quotation Marks
    func test_QuotationMark_CompletedByAnotherOne() {
        textView.text = "test "
        cursorOffsetFromEnd = 0
        textView.insertAsCode("\"")
        
        XCTAssertEqual(textView.text, "test \"\"")  // One additional quotation mark
        XCTAssertEqual(cursorOffsetFromEnd, -1)     // Between the quotes
    }
    
    func test_QuotationMark_TreatedNormally_IfUnevenNumberOfQuotesInDocument() {
        textView.text = "\"test"
        cursorOffsetFromEnd = 0
        textView.insertAsCode("\"")
        
        XCTAssertEqual(textView.text, "\"test\"")   // No additional quotation mark
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
    
    func test_QuotationMarkBeforeQuotationMark_StepsOver_IfEvenNumberOfQuotesInDocument() {
        textView.text = "\"test\""
        cursorOffsetFromEnd = -1    // After "test"
        textView.insertAsCode("\"")
        
        XCTAssertEqual(textView.text, "\"test\"")   // One additional quotation mark
        XCTAssertEqual(cursorOffsetFromEnd, 0)
    }
}
