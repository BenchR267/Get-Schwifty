import Foundation

private let letters = CharacterSet.letters
private let digits = CharacterSet.decimalDigits
private let whitespaces = CharacterSet.whitespacesAndNewlines
private let keywords = Set(["associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func", "import", "init", "inout", "internal", "let", "open", "operator", "private", "protocol", "public", "static", "struct", "subscript", "typealias", "var", "break", "case", "continue", "default", "defer", "do", "else", "fallthrough", "for", "guard", "if", "in", "repeat", "return", "switch", "where", "while", "as", "Any", "catch", "false", "is", "nil", "rethrows", "super", "self", "Self", "throw", "throws", "true", "try", "associativity", "convenience", "dynamic", "didSet", "final", "get", "infix", "indirect", "lazy", "left", "mutating", "none", "nonmutating", "optional", "override", "postfix", "precedence", "prefix", "Protocol", "required", "right", "set", "Type", "unowned", "weak", "willSet"])

public enum LiteralType {
    case Integer(Int)
    case String(String)
    case Double(Double)
}

public enum TokenType: Equatable {
    case identifier
    case keyword
    case parenthesisOpen
    case parenthesisClose
    case curlyBracketOpen
    case curlyBracketClose
    case squareBracketOpen
    case squareBracketClose
    case questionMark
    case bang
    case underscore
    case and
    case or
    case logicalAnd
    case logicalOr
    case arrow
    case comma
    case point
    case colon
    case assign
    case plus
    case minus
    case slash
    case multiply
    case percent
    case equal
    case notEqual
    case greater
    case less
    case greaterEqual
    case lessEqual
    case literal(LiteralType)
    case comment(String)
    case illegal
    case space
    case tab
    case newLine
    
    // RawRepresentable needs also the other way around, not needed here
    public init?(rawValue: String) {
        guard !rawValue.isEmpty else {
            return nil
        }
        
        switch rawValue {
        case "(":
            self = .parenthesisOpen
        case ")":
            self = .parenthesisClose
        case "{":
            self = .curlyBracketOpen
        case "}":
            self = .curlyBracketClose
        case "[":
            self = .squareBracketOpen
        case "]":
            self = .squareBracketClose
        case "?":
            self = .questionMark
        case "!":
            self = .bang
        case "_":
            self = .underscore
        case "|":
            self = .or
        case "||":
            self = .logicalOr
        case "&":
            self = .and
        case "&&":
            self = .logicalAnd
        case "->":
            self = .arrow
        case ",":
            self = .comma
        case ".":
            self = .point
        case ":":
            self = .colon
        case "=":
            self = .assign
        case "+":
            self = .plus
        case "-":
            self = .minus
        case "/":
            self = .slash
        case "*":
            self = .multiply
        case "%":
            self = .percent
        case "==":
            self = .equal
        case "!=":
            self = .notEqual
        case ">":
            self = .greater
        case "<":
            self = .less
        case ">=":
            self = .greaterEqual
        case "<=":
            self = .lessEqual
        case " ":
            self = .space
        case "\t":
            self = .tab
        case "\n":
            self = .newLine
        default:
            if let i = Int(rawValue) {
                self = .literal(.Integer(i))
            } else if let d = Double(rawValue) {
                self = .literal(.Double(d))
            } else if consistsOfLettersOrDigits(rawValue) {
                if keywords.contains(rawValue) {
                    self = .keyword
                    return
                }
                self = .identifier
            } else if rawValue.hasPrefix("\"") && rawValue.hasSuffix("\"") {
                self = .literal(.String(rawValue))
            } else if rawValue.hasPrefix("//") {
                self = .comment(rawValue)
            } else {
                self = .illegal
            }
        }
    }
    
    public static func ==(lhs: TokenType, rhs: TokenType) -> Bool {
        switch (lhs, rhs) {
        case (.identifier, .identifier): return true
        case (.keyword, .keyword): return true
        case (.parenthesisOpen, .parenthesisOpen): return true
        case (.parenthesisClose, .parenthesisClose): return true
        case (.curlyBracketOpen, .curlyBracketOpen): return true
        case (.curlyBracketClose, .curlyBracketClose): return true
        case (.squareBracketOpen, .squareBracketOpen): return true
        case (.squareBracketClose, .squareBracketClose): return true
        case (.questionMark, .questionMark): return true
        case (.bang, .bang): return true
        case (.underscore, .underscore): return true
        case (.and, .and): return true
        case (.or, .or): return true
        case (.logicalAnd, .logicalAnd): return true
        case (.logicalOr, .logicalOr): return true
        case (.arrow, .arrow): return true
        case (.comma, .comma): return true
        case (.point, .point): return true
        case (.colon, .colon): return true
        case (.assign, .assign): return true
        case (.plus, .plus): return true
        case (.minus, .minus): return true
        case (.slash, .slash): return true
        case (.multiply, .multiply): return true
        case (.percent, .percent): return true
        case (.equal, .equal): return true
        case (.notEqual, .notEqual): return true
        case (.greater, .greater): return true
        case (.less, .less): return true
        case (.greaterEqual, .greaterEqual): return true
        case (.lessEqual, .lessEqual): return true
        case (.illegal, .illegal): return true
        case (.space, .space): return true
        case (.newLine, .newLine): return true
        case (.tab, .tab): return true
        case (.literal(.Integer(let i)), .literal(.Integer(let j))): return i == j
        case (.literal(.String(let a)), .literal(.String(let b))): return a == b
        case (.comment(let a), .comment(let b)): return a == b
        default: return false
        }
    }
}

extension String {
    var withoutDollar: String {
        if self.hasPrefix("$") {
            return self.unicodeScalars.dropFirst().string
        } else {
            return self
        }
    }
}

func consistsOfLettersOrDigits(_ raw: String) -> Bool {
    for c in raw.withoutDollar.unicodeScalars {
        if !letters.contains(c) && !digits.contains(c) {
            return false
        }
    }
    return true
}

func isWhitespace(_ raw: UnicodeScalar) -> Bool {
    return whitespaces.contains(raw)
}

public struct Location {
    var row, column, len: Int
}

public class Token {
    public let loc: Location
    public let type: TokenType
    public let raw: String
    
    init(loc: Location, type: TokenType, raw: String) {
        self.loc = loc
        self.type = type
        self.raw = raw
    }
}

public class Lexer {
    
    let input: String
    let tokenizer = Tokenizer()
    var currLoc = Location(row: 1, column: 0, len: 0)
    public init(input: String) {
        self.input = input
    }
    
    public func start() -> [Token] {
        
        var tokens = [Token]()
        
        for c in self.input.unicodeScalars {
            let token: Token?
            if !isWhitespace(c) || (c != "\n" && self.tokenizer.needsMore) || (c != "\n" && self.tokenizer.comment) {
                token = self.tokenizer.append(char: c, loc: self.currLoc)
            } else {
                token = self.tokenizer.token(loc: self.currLoc)
            }
            
            if let t = token {
                tokens.append(t)
            }
            
            if c == "\n" {
                tokens.append(Token(loc: self.currLoc, type: .newLine, raw: "\n"))
                if self.tokenizer.comment {
                    self.tokenizer.comment = false
                    if let t = self.tokenizer.token(loc: self.currLoc) {
                        tokens.append(t)
                    }
                }
                self.currLoc.column = -1 // will always be incremented
                self.currLoc.row += 1
            } else if c == " " && !self.tokenizer.needsMore && !self.tokenizer.comment {
                tokens.append(Token(loc: self.currLoc, type: .space, raw: " "))
            } else if c == "\t" && !self.tokenizer.needsMore && !self.tokenizer.comment {
                tokens.append(Token(loc: self.currLoc, type: .tab, raw: "\t"))
            }
            self.currLoc.column += 1
        }
        
        if let t = self.tokenizer.token(loc: self.currLoc) {
            tokens.append(t)
        }
        
        return tokens
    }
    
}

class Tokenizer {
    
    private(set) var buffer = [UnicodeScalar]()
    private var escaped = false
    var comment = false
    
    var needsMore: Bool {
        switch buffer.count {
        case 1:
            return buffer.first == "\""
        case 1..<Int.max:
            return buffer.first == "\"" && buffer.last != "\""
        default:
            return false
        }
    }
    
    func append(char: UnicodeScalar, loc: Location) -> Token? {
        defer {
            self.buffer.append(char)
        }
        
        return belongsTogether(curr: self.buffer, next: char) ? nil : self.token(loc: loc)
    }
    
    func token(loc: Location) -> Token? {
        let buffer = self.buffer.string
        
        guard let type = TokenType(rawValue: buffer) else {
            return nil
        }
        
        let length = self.buffer.count
        self.buffer = []
        
        var location = loc
        location.column -= length
        location.len = length
        return Token(loc: location, type: type, raw: buffer)
    }
    
    func belongsTogether(curr: [UnicodeScalar], next: UnicodeScalar) -> Bool {
        if self.comment {
            return true
        }
        
        if self.escaped {
            self.escaped = false
            return true
        }
        
        if next == "\\" {
            self.escaped = true
            return true
        }
        
        if curr.string == "/" && next == "/" {
            self.comment = true
            return true
        }
        
        guard !curr.isEmpty else {
            return true
        }
        
        if self.needsMore {
            return true
        }
        
        let string = curr.string
        
        if Double(string) != nil {
            return Double((curr + [next]).string) != nil
        }
        
        if curr.count == 1 {
            switch curr[0] {
            case "+":
                return next == "+"
            case "!", "=":
                return next == "="
            case "<":
                return next == "="
            case ">":
                return next == "="
            case "-":
                return next == ">"
            case "|":
                return next == "|"
            case "&":
                return next == "&"
            case "/":
                return next == "/"
            default:
                return letters.contains(curr[0]) && letters.contains(next)
            }
        } else if curr.count == 2 {
            guard let token = TokenType(rawValue: string) else {
                return false
            }
            
            
            switch token {
            case .identifier, .illegal, .literal(.String(_)), .keyword:
                return letters.contains(next)
            case .literal(.Integer(_)):
                return digits.contains(next)
            default:
                return false
            }
        } else {
            let string = curr.string
            guard let token = TokenType(rawValue: string), token != .illegal else {
                return false
            }
            switch token {
            case .literal(.String(_)):
                return false
            default:
                return letters.contains(next) && consistsOfLettersOrDigits(string)
            }
        }
    }
    
}

extension Collection where Iterator.Element == UnicodeScalar {
    
    var string: String {
        return self.map { String($0) }.joined()
    }
    
}
