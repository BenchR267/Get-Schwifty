//
//  Parser.swift
//  WWDC
//
//  Created by Benjamin Herzog on 01.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import Foundation

public class Parser {

    public indirect enum Error: Swift.Error, Equatable, Hashable {
        case unexpectedError
        case unexpectedEOF
        case unexpectedType(expected: TokenType, got: Token)
        case unexpectedString(expected: String, got: String)
        case couldNotInferType(String, Location?)
        case unexpectedExpression(expectedType: String, got: String)

        case unknownIdentifier(String)
        case wrongType(expected: String, got: String)
        case mutatingNonMutatingVariable(String)

        case multiple([Error])
        case unimplemented

        var string: String {
            switch self {
            case .unexpectedError: return "Unexpected Error :("
            case .unexpectedEOF: return "File ended unexpected"
            case .unexpectedType(let expected, let got): return "Expected \(expected) but got \(got.type) instead"
            case .unexpectedString(let expected, let got): return "Expected \(expected) but got \(got) instead"
            case .couldNotInferType(let id, _): return "Could not infer type of \(id)."
            case .unexpectedExpression(let expectedType, let got): return "Expression is unexpected: \(got) instead of \(expectedType)"
            case .unknownIdentifier(let id): return "Got unknown identifier '\(id)'"
            case .wrongType(let expected, let got): return "type mismatch: expected \(expected), got \(got)"
            case .mutatingNonMutatingVariable(let id): return "\(id) can not be mutated."
            case .multiple(let errors):
                let errorStrings = Set(errors.flatMap { $0.children.map { "* " + $0.string } })
                return "Multiple errors are possible: \n" + errorStrings.joined(separator: "\n")
            case .unimplemented: return "This functionality is unimplemented."
            }
        }

        var children: Set<Error> {
            switch self {
            case .multiple(let errors):
                return Set(errors.flatMap { Set($0.children) })
            default:
                return Set([self])
            }
        }

        public static func ==(lhs: Error, rhs: Error) -> Bool {
            switch (lhs, rhs) {
            case (.unexpectedError, .unexpectedError): return true
            case (.unexpectedEOF, .unexpectedEOF): return true
            case (.unexpectedType, .unexpectedType): return true
            case (.unexpectedString, .unexpectedString): return true
            case (.couldNotInferType, .couldNotInferType): return true
            case (.unexpectedExpression, .unexpectedExpression): return true
            case (.unknownIdentifier, .unknownIdentifier): return true
            case (.wrongType, .wrongType): return true
            case (.mutatingNonMutatingVariable, .mutatingNonMutatingVariable): return true
            case (.multiple, .multiple): return true
            case (.unimplemented, .unimplemented): return true
            default: return false
            }
        }

        public var hashValue: Int {
            switch self {
            case .unexpectedError: return 1
            case .unexpectedEOF: return 2
            case .unexpectedType(_, _): return 3
            case .unexpectedString(_, _): return 4
            case .couldNotInferType(_, _): return 5
            case .unexpectedExpression(_, _): return 6
            case .unknownIdentifier(_): return 7
            case .wrongType(_, _): return 8
            case .mutatingNonMutatingVariable(_): return 9
            case .multiple(_): return 10
            case .unimplemented: return 11
            }
        }
    }

    private static let standardNamelist = [
        "alert": IdentifierInformation(type: "Void", mutable: false),
        "sleep": IdentifierInformation(type: "Void", mutable: false),
        "print": IdentifierInformation(type: "Void", mutable: false)
    ]

    private let tokens: [Token]
    private var iterator: Int
    public init(tokens: [Token]) {
        self.tokens = tokens.filter {
            switch $0.type {
            case .space, .newLine, .tab, .comment(_):
                return false
            default:
                return true
            }
        }
        self.iterator = 0
    }

    func reset() {
        self.iterator = 0
    }

    private func iteratedElement() -> Token? {
        return self.tokens.count <= self.iterator ? nil : self.tokens[self.iterator]
    }

    private func peekedElement() -> Token? {
        return self.tokens.count <= self.iterator + 1 ? nil : self.tokens[self.iterator + 1]
    }

    private func nextToken() {
        self.iterator += 1
    }

    @discardableResult
    private func parse(_ tokenType: TokenType) throws -> String {
        guard let current = self.iteratedElement() else {
            throw Error.unexpectedEOF
        }
        if current.type != tokenType {
            throw Error.unexpectedType(expected: tokenType, got: current)
        }
        self.nextToken()
        return current.raw
    }

    func parseProgram() throws -> Program {
        let scope = try self.parseScope(list: Parser.standardNamelist)
        if let additional = self.iteratedElement() {
            throw Error.unexpectedString(expected: "EOF", got: additional.raw)
        }
        return Program(scope: scope)
    }

    private func parseScope(list: [String: IdentifierInformation], withReturn: Bool = false) throws -> Scope {
        var statements = [Statement]()
        var namelist = list
        while let next = iteratedElement(), next.type != .curlyBracketClose {
            let statement = try parseStatement(namelist: &namelist, withReturn: withReturn)
            statements.append(statement)
        }
        return Scope(statements: statements, namelist: namelist)
    }

    private func parseStatement(namelist: inout [String: IdentifierInformation], withReturn: Bool = false) throws -> Statement {
        let start = self.iterator
        var errors = [Error]()

        if withReturn {
            do {
                let raw = try self.parse(.keyword)
                if raw != "return" {
                    throw Error.unexpectedString(expected: "return", got: raw)
                }
                return .returnE(try? self.parseExpression(namelist: &namelist))
            } catch let error as Parser.Error {
                errors.append(error)
            }
        }

        // reset to begin of statement
        self.iterator = start
        do {
            let decl = try self.parseDeclaration(namelist: &namelist)
            return .declaration(decl)
        } catch let error as Parser.Error {
            errors.append(error)
        }

        self.iterator = start
        do {
            let control = try self.parseControlStructure(namelist: &namelist, withReturn: withReturn)
            return .controlStructure(control)
        } catch let error as Parser.Error {
            errors.append(error)
        }

        self.iterator = start
        do {
            let ass = try self.parseAssignment(namelist: &namelist)
            return .assignment(ass)
        } catch let error as Parser.Error {
            errors.append(error)
        }

        self.iterator = start
        do {
            let expr = try self.parseExpression(namelist: &namelist)
            return .expression(expr)
        } catch let error as Parser.Error {
            errors.append(error)
        }

        throw Error.multiple(errors)
    }

    private func parseDeclaration(namelist: inout [String: IdentifierInformation]) throws -> Declaration {
        let keyword = try self.parseKeyword()
        switch keyword {
        case "var":
            return .variable(try self.parseVariableDecl(namelist: &namelist))
        case "let":
            return .constant(try self.parseLetDecl(namelist: &namelist))
        case "func":
            return .function(try self.parseFunctionDecl(namelist: &namelist))
        default:
            throw Error.unimplemented
        }
    }

    private func parseFunctionDecl(namelist: inout [String: IdentifierInformation]) throws -> FunctionDecl {
        let name = try self.parseIdentifier().raw
        try self.parse(.parenthesisOpen)
        var parameters = [ParameterDecl]()
        while let next = self.iteratedElement(), next.type != .parenthesisClose {
            parameters.append(try self.parseParameterDecl(namelist: &namelist))
            if let next = self.iteratedElement(), next.type != .parenthesisClose {
                try self.parse(.comma)
            }
        }
        try self.parse(.parenthesisClose)
        var returnType = "Void"
        if let next = self.iteratedElement(), next.type != .curlyBracketOpen {
            try self.parse(.arrow)
            returnType = try self.parseIdentifier().raw
        }
        try self.parse(.curlyBracketOpen)

        var stack = namelist
        for p in parameters {
            stack[p.name] = IdentifierInformation(type: p.type, mutable: false)
        }
        stack[name] = IdentifierInformation(type: returnType, mutable: false)
        let body = try self.parseFunctionBody(namelist: &stack, returnType: returnType)
        // TODO: check for return expression if return type is not Void!
        try self.parse(.curlyBracketClose)
        namelist[name] = IdentifierInformation(type: returnType, mutable: false)
        for (i, p) in parameters.enumerated() {
            namelist["_func_\(name)_\(i)"] = IdentifierInformation(type: p.type, mutable: false)
        }
        return FunctionDecl(name: name, parameters: parameters, returnType: returnType, body: body)
    }

    private func parseFunctionBody(namelist: inout [String: IdentifierInformation], returnType: String) throws -> FunctionBody {
        let scope = try self.parseScope(list: namelist, withReturn: true)
        let returnFound = try checkScope(scope: scope, namelist: scope.namelist, returnType: returnType)
        if returnType != "Void" && !returnFound {
            throw Error.unexpectedExpression(expectedType: "return", got: "}")
        }
        return FunctionBody(statements: scope.statements)
    }

    // returns if matching return was found
    private func checkScope(scope: Scope, namelist: [String: IdentifierInformation], returnType: String) throws -> Bool {
        var found = false
        for s in scope.statements {
            switch s {
            case .returnE(let e):
                if !(e?.type(namelist).typeMatches(returnType) ?? (returnType != "Void")) {
                    throw Error.wrongType(expected: returnType, got: e?.type(namelist) ?? "Void")
                } else {
                    found = true
                }
            case .controlStructure(let c):
                switch c {
                case .forS(_):
                    throw Error.unimplemented
                case .ifS(let i):
                    for condition in i.conditions {
                        found = try checkScope(scope: condition.1, namelist: namelist, returnType: returnType) || found
                    }
                    if let elseS = i.elseS {
                        found = try checkScope(scope: elseS, namelist: namelist, returnType: returnType) || found
                    }
                case .whileS(let w):
                    found = try checkScope(scope: w.scope, namelist: namelist, returnType: returnType) || found
                }
            default:
                continue
            }
        }
        return found
    }

    private func parseVariableDecl(namelist: inout [String: IdentifierInformation]) throws -> VariableDecl {
        let loc = self.iteratedElement()?.loc
        var param = try self.parseParameterDecl(namelist: &namelist)
        var expr: Expression? = nil
        if let next = self.iteratedElement(), next.type == .assign {
            try self.parse(.assign)
            expr = try self.parseExpression(namelist: &namelist)
        }
        guard let type = param.type.isEmpty ? expr?.type(namelist) : param.type else {
            throw Error.couldNotInferType(param.name, loc)
        }
        param.type = type
        namelist[param.name] = IdentifierInformation(type: type, mutable: true)
        return VariableDecl(parameter: param, expression: expr)
    }

    private func parseLetDecl(namelist: inout [String: IdentifierInformation]) throws -> LetDecl {
        let loc = self.iteratedElement()?.loc
        var param = try self.parseParameterDecl(namelist: &namelist)
        var expr: Expression? = nil
        if let next = self.iteratedElement(), next.type == .assign {
            try self.parse(.assign)
            expr = try self.parseExpression(namelist: &namelist)
        }
        if let exprType = expr?.type(namelist), !param.type.isEmpty, !exprType.typeMatches(param.type) {
            throw Error.wrongType(expected: param.type, got: exprType)
        }
        guard let type = param.type.isEmpty ? expr?.type(namelist) : param.type else {
            throw Error.couldNotInferType(param.name, loc)
        }
        param.type = type
        namelist[param.name] = IdentifierInformation(type: type, mutable: false)
        return LetDecl(parameter: param, expression: expr)
    }

    private func parseParameterDecl(namelist: inout [String: IdentifierInformation]) throws -> ParameterDecl {
        let identifier = try self.parseIdentifier().raw
        var type = ""
        if let next = self.iteratedElement(), next.type == .colon {
            try self.parse(.colon)
            type = try self.parseIdentifier().raw
        }
        return ParameterDecl(name: identifier, type: type)
    }

    private func parseControlStructure(namelist: inout [String: IdentifierInformation], withReturn: Bool = false) throws -> ControlStructure {
        let keyword = try self.parseKeyword()
        switch keyword {
            case "if":
                return .ifS(try self.parseIf(namelist: &namelist, withReturn: withReturn))
            case "while":
                return .whileS(try self.parseWhile(namelist: &namelist, withReturn: withReturn))
            case "for":
                return.forS(try self.parseFor(namelist: &namelist, withReturn: withReturn))
        default: throw Error.unimplemented
        }
    }

    private func parseIf(namelist: inout [String: IdentifierInformation], withReturn: Bool = false) throws -> If {

        var conditions = [(MultipleCondition, Scope)]()

        let first = try self.parseSpecificIf(namelist: &namelist, withReturn: withReturn) // if itself
        conditions.append(first)

        while let next = self.iteratedElement(),
              let overNext = self.peekedElement(),
            next.raw == "else", overNext.raw == "if" {
                self.nextToken() // 'else'
                self.nextToken() // 'if'
                conditions.append(try self.parseSpecificIf(namelist: &namelist, withReturn: withReturn))
        }

        var elseS: Scope? = nil
        if let next = self.iteratedElement(), next.type == .keyword && next.raw == "else" {
            self.nextToken() // 'else'
            try self.parse(.curlyBracketOpen)
            elseS = try self.parseScope(list: namelist, withReturn: withReturn)
            try self.parse(.curlyBracketClose)
        }
        if conditions.count < 1 {
            throw Error.unexpectedString(expected: "condition", got: "{")
        }
        return If(conditions: conditions, elseS: elseS)
    }

    private func parseSpecificIf(namelist: inout [String: IdentifierInformation], withReturn: Bool = false) throws -> (MultipleCondition, Scope) {
        let multipleCondition = try self.parseMultipleCondition(namelist: &namelist)
        try self.parse(.curlyBracketOpen)
        let scope = try self.parseScope(list: namelist, withReturn: withReturn)
        try self.parse(.curlyBracketClose)
        return (multipleCondition, scope)
    }

    private func parseMultipleCondition(namelist: inout [String: IdentifierInformation], rec: Bool = true) throws -> MultipleCondition {
        var expressions = [Expression]()
        var operators = [Token]()
        while let next = self.iteratedElement(), next.type != .curlyBracketOpen {
            // ignore ( ) for now
            if next.type == .parenthesisOpen || next.type == .parenthesisClose {
                continue
            }
            let expression = try parseExpression(namelist: &namelist, condition: rec, calculation: false)
            if expression.type(namelist) != "Bool" {
                throw Error.unexpectedExpression(expectedType: "Bool", got: expression.type(namelist))
            }
            expressions.append(expression)
            if let next = self.iteratedElement(), next.type == .logicalAnd || next.type == .logicalOr {
                operators.append(try self.parseLogicalOperator())
            }
        }
        if operators.count != expressions.count - 1 {
            throw Error.unexpectedString(expected: "one operator less than conditions", got: "Too much or less operators")
        }
        return MultipleCondition(conditions: expressions, operators: operators)
    }

    private func parseMutlipleCalculation(namelist: inout [String: IdentifierInformation], rec: Bool = true) throws -> MultipleCalculation {
        var expressions = [Expression]()
        var operators = [String]()
        var go = true
        while go {
            let expr = try self.parseExpression(namelist: &namelist, calculation: rec)
            expressions.append(expr)
            if let next = self.iteratedElement() {
                switch next.type {
                case .plus, .minus, .multiply, .slash:
                    let op = try self.parseCalculationOperator()
                    operators.append(op.raw)
                default:
                    go = false
                }
            } else {
                go = false
            }
        }
        if operators.count != expressions.count - 1 {
            throw Error.unexpectedString(expected: "one operator less than conditions", got: "Too much or less operators")
        }
        if expressions.count == 1 {
            throw Error.unexpectedExpression(expectedType: "calculation should be more than one expression", got: "one expression")
        }
        return MultipleCalculation(expressions: expressions, operators: operators)
    }

    private func parseCondition(namelist: inout [String: IdentifierInformation], rec: Bool = true) throws -> Condition {
        let expr1 = try self.parseExpression(namelist: &namelist, condition: rec, calculation: false)
        let op = try self.parseBoolOperator()
        let expr2 = try self.parseExpression(namelist: &namelist, condition: rec, calculation: false)
        return Condition(expr1: expr1, operatorT: op, expr2: expr2)
    }

    private func parseWhile(namelist: inout [String: IdentifierInformation], withReturn: Bool = false) throws -> While {
        let expression = try parseMultipleCondition(namelist: &namelist)
        try self.parse(.curlyBracketOpen)
        let scope = try self.parseScope(list: namelist, withReturn: withReturn)
        try self.parse(.curlyBracketClose)
        return While(expression: expression, scope: scope)
    }

    private func parseCall(namelist: inout [String: IdentifierInformation]) throws -> Call {
        let name = try self.parseIdentifier().raw
        try namelist.lookup(name)
        try self.parse(.parenthesisOpen)
        var exprs = [Expression]()
        var i = 0
        while let next = self.iteratedElement(), next.type != .parenthesisClose {
            let expr = try self.parseExpression(namelist: &namelist)
            exprs.append(expr)
            if let type = namelist["_func_\(name)_\(i)"]?.type, !type.typeMatches(expr.type(namelist)) {
                throw Error.wrongType(expected: type, got: expr.type(namelist))
            }
            if let next = self.iteratedElement(), next.type != .parenthesisClose {
                try self.parse(.comma)
            }
            i += 1
        }
        try self.parse(.parenthesisClose)
        return Call(name: name, parameters: exprs)
    }

    private func parseFor(namelist: inout [String: IdentifierInformation], withReturn: Bool = false) throws -> For {
        // TODO
        throw Error.unimplemented
    }

    private func parseExpression(namelist: inout [String: IdentifierInformation], condition: Bool = true, calculation: Bool = true) throws -> Expression {

        let start = self.iterator
        var errors = [Error]()
        if condition {
            do {
                let condition = try self.parseCondition(namelist: &namelist, rec: false)
                return .condition(condition)
            } catch let error as Error {
                errors.append(error)
            }
        }

        self.iterator = start
        if calculation {
            do {
                let calc = try self.parseMutlipleCalculation(namelist: &namelist, rec: false)
                return .calculation(calc)
            } catch let error as Error {
                errors.append(error)
            }
        }

        self.iterator = start
        do {
            return .call(try self.parseCall(namelist: &namelist))
        } catch let error as Error {
            errors.append(error)
        }

        self.iterator = start
        do {
            return .literal(try self.parseLiteral())
        } catch let error as Error {
            errors.append(error)
        }

        self.iterator = start
        do {
            let identifier = try self.parseIdentifier()
            try namelist.lookup(identifier.raw)
            return .identifier(identifier)
        } catch let error as Error {
            errors.append(error)
        }

        throw Error.multiple(errors)
    }

    private func parseAssignment(namelist: inout [String: IdentifierInformation]) throws -> Assignment {
        let identifier = try self.parseIdentifier()
        var tokenType = TokenType.assign
        if let next = self.iteratedElement() {
            tokenType = next.type
            if ![TokenType.assign, .minusAssign, .plusAssign].contains(tokenType) {
                throw Error.unexpectedString(expected: "= += -=", got: next.raw)
            }
            self.nextToken()
        }
        let expr = try self.parseExpression(namelist: &namelist)
        try namelist.lookup(identifier.raw)
        guard namelist[identifier.raw]!.mutable else {
            throw Error.mutatingNonMutatingVariable(identifier.raw)
        }
        if let type = namelist[identifier.raw]?.type, !type.typeMatches(expr.type(namelist)) {
            throw Error.wrongType(expected: type, got: expr.type(namelist))
        }
        var finalExpression = expr
        if tokenType == .plusAssign {
            finalExpression = Expression.calculation(MultipleCalculation(expressions: [.identifier(identifier), expr], operators: ["+"]))
        } else if tokenType == .minusAssign {
            finalExpression = Expression.calculation(MultipleCalculation(expressions: [.identifier(identifier), expr], operators: ["-"]))
        }

        return Assignment(identifer: identifier, expression: finalExpression)
    }

    private func parseLiteral() throws -> Token {
        guard let current = self.iteratedElement() else {
            throw Error.unexpectedEOF
        }
        if case .literal(_) = current.type {
            self.nextToken()
            return current
        }
        throw Error.unexpectedString(expected: "literal", got: current.raw)
    }

    private func parseIdentifier() throws -> Token {
        let raw = self.iteratedElement()
        try self.parse(.identifier)
        return raw!
    }

    private func parseKeyword() throws -> String {
        let raw = self.iteratedElement()?.raw
        try self.parse(.keyword)
        return raw!
    }

    private func parseCalculationOperator() throws -> Token {
        guard let token = self.iteratedElement() else {
            throw Error.unexpectedEOF
        }

        switch token.type {
        case .plus, .minus, .multiply, .slash:
            self.nextToken()
            return token
        default:
            throw Error.unexpectedString(expected: "+ - * /", got: token.raw)
        }
    }

    private func parseBoolOperator() throws -> Token {
        guard let token = self.iteratedElement() else {
            throw Error.unexpectedEOF
        }

        switch token.type {
        case .equal, .notEqual, .greater, .greaterEqual, .less, .lessEqual:
            self.nextToken()
            return token
        default:
            throw Error.unexpectedString(expected: "== != > >= < <=", got: token.raw)
        }
    }

    private func parseLogicalOperator() throws -> Token {
        guard let token = self.iteratedElement() else {
            throw Error.unexpectedEOF
        }

        switch token.type {
        case .logicalAnd, .logicalOr:
            self.nextToken()
            return token
        default:
            throw Error.unexpectedString(expected: "&& ||", got: token.raw)
        }
    }

}

extension String {

    func typeMatches(_ other: String) -> Bool {
        switch self {
        case "Int", "Double", "Float":
            return other == "Int" || other == "Double" || other == "Float"
        default: return self == other
        }
    }

}

extension Dictionary where Key == String, Value == IdentifierInformation {

    func lookup(_ identifier: String) throws {
        guard self[identifier] != nil else {
            throw Parser.Error.unknownIdentifier(identifier)
        }
    }

    func assert(_ identifier: String, type: String) throws {
        guard let got = self[identifier]?.type else {
            throw Parser.Error.unknownIdentifier(identifier)
        }
        if got.typeMatches(type) {
            throw Parser.Error.wrongType(expected: type, got: got)
        }
    }

}
