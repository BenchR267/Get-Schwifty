//
//  Parser.swift
//  WWDC
//
//  Created by Benjamin Herzog on 01.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import Foundation

public class Parser {
    
    public indirect enum Error: Swift.Error {
        case eof
        case unexpectedEOF
        case unexpectedType(expected: TokenType, got: Token)
        case unexpectedString(expected: String, got: String)
        case couldNotInferType(String, Location?)
        case unexpectedExpression(expectedType: String, got: String)
        
        case merged(Error, Error)
        
        case unimplemented
    }
    
    private let tokens: [Token]
    private var iterator: Int
    public init(input: String) {
        let lexer = Lexer(input: input)
        self.tokens = lexer.start().filter {
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
    
    private func parse(_ tokenType: TokenType) throws {
        guard let current = self.iteratedElement() else {
            throw Error.unexpectedEOF
        }
        if current.type != tokenType {
            throw Error.unexpectedType(expected: tokenType, got: current)
        }
        self.nextToken()
    }
    
    func parseProgram() throws -> Program {
        let scope = try self.parseScope()
        if let additional = self.iteratedElement() {
            throw Error.unexpectedString(expected: "EOF", got: additional.raw)
        }
        return Program(scope: scope)
    }
    
    private func parseScope() throws -> Scope {
        var statements = [Statement]()
        while let next = iteratedElement(), next.type != .curlyBracketClose {
            let statement = try parseStatement()
            statements.append(statement)
        }
        return Scope(statements: statements)
    }
    
    private func parseStatement() throws -> Statement {
        var errors = [Error]()
        do {
            let decl = try self.parseDeclaration()
            return .declaration(decl)
        } catch let error as Parser.Error {
            errors.append(error)
        }
        
//        do {
//            let decl = try self.parseDeclaration()
//        } catch let error as Parser.Error {
//            errors.append(error)
//        }

        let error = errors.reduce(Error.eof) { Error.merged($0, $1) }
        throw error
    }
    
    private func parseDeclaration() throws -> Declaration {
        let keyword = try self.parseKeyword()
        switch keyword {
        case "var":
            return .variable(try self.parseVariableDecl())
        case "let":
            return .constant(try self.parseLetDecl())
        case "func":
            return .function(try self.parseFunctionDecl())
        default:
            throw Error.unexpectedString(expected: "var, let, func", got: keyword)
        }
    }
    
    private func parseFunctionDecl() throws -> FunctionDecl {
        let name = try self.parseIdentifier().raw
        try self.parse(.parenthesisOpen)
        var parameters = [ParameterDecl]()
        while let next = self.iteratedElement(), next.type != .parenthesisClose {
            parameters.append(try self.parseParameterDecl())
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
        let body = try self.parseFunctionBody()
        if returnType != "Void" && body.returnExpr == nil {
            throw Error.unexpectedString(expected: "return", got: "")
        }
        try self.parse(.curlyBracketClose)
        return FunctionDecl(name: name, parameters: parameters, returnType: returnType, body: body)
    }
    
    private func parseFunctionBody() throws -> FunctionBody {
        var statements = [Statement]()
        while let token = iteratedElement(), token.type != .curlyBracketClose {
            if let next = self.iteratedElement(), next.type == .keyword, next.raw == "return" {
                try self.parse(.keyword)
                return FunctionBody(statements: statements, returnExpr: try self.parseExpression())
            }
            let statement = try parseStatement()
            statements.append(statement)
        }
        return FunctionBody(statements: statements, returnExpr: nil)
    }
    
    private func parseVariableDecl() throws -> VariableDecl {
        let loc = self.iteratedElement()?.loc
        var param = try self.parseParameterDecl()
        var expr: Expression? = nil
        if let next = self.iteratedElement(), next.type == .assign {
            try self.parse(.assign)
            expr = try self.parseExpression()
        }
        guard let type = param.type.isEmpty ? expr?.type : param.type else {
            throw Error.couldNotInferType(param.name, loc)
        }
        param.type = type
        return VariableDecl(parameter: param, expression: expr)
    }
    
    private func parseLetDecl() throws -> LetDecl {
        let loc = self.iteratedElement()?.loc
        var param = try self.parseParameterDecl()
        var expr: Expression? = nil
        if let next = self.iteratedElement(), next.type == .assign {
            try self.parse(.assign)
            expr = try self.parseExpression()
        }
        guard let type = param.type.isEmpty ? expr?.type : param.type else {
            throw Error.couldNotInferType(param.name, loc)
        }
        param.type = type
        return LetDecl(parameter: param, expression: expr)
    }
    
    private func parseParameterDecl() throws -> ParameterDecl {
        let identifier = try self.parseIdentifier().raw
        var type = ""
        if let next = self.iteratedElement(), next.type == .colon {
            try self.parse(.colon)
            type = try self.parseIdentifier().raw
        }
        return ParameterDecl(name: identifier, type: type)
    }
    
    func parseControlStructure() throws -> ControlStructure {
        let keyword = try self.parseKeyword()
        switch keyword {
            case "if":
                return .ifS(try self.parseIf())
        default: throw Error.unimplemented
        }
    }
    
    private func parseIf() throws -> If {
        
        var conditions = [(MultipleCondition, Scope)]()
        
        let first = try self.parseSpecificIf() // if itself
        conditions.append(first)
        
        while let next = self.iteratedElement(),
              let overNext = self.peekedElement(),
            next.raw == "else", overNext.raw == "if" {
                self.nextToken() // 'else'
                self.nextToken() // 'if'
                conditions.append(try self.parseSpecificIf())
        }
        
        var elseS: Scope? = nil
        if let next = self.iteratedElement(), next.type == .keyword && next.raw == "else" {
            self.nextToken() // 'else'
            try self.parse(.curlyBracketOpen)
            elseS = try self.parseScope()
            try self.parse(.curlyBracketClose)
        }
        if conditions.count < 1 {
            throw Error.unexpectedString(expected: "condition", got: "{")
        }
        return If(conditions: conditions, elseS: elseS)
    }
    
    private func parseSpecificIf() throws -> (MultipleCondition, Scope) {
        let multipleCondition = try self.parseMultipleCondition()
        try self.parse(.curlyBracketOpen)
        let scope = try self.parseScope()
        try self.parse(.curlyBracketClose)
        return (multipleCondition, scope)
    }
    
    private func parseMultipleCondition() throws -> MultipleCondition {
        var expressions = [Expression]()
        var operators = [Token]()
        while let next = self.iteratedElement(), next.type != .curlyBracketOpen {
            // ignore ( ) for now
            if next.type == .parenthesisOpen || next.type == .parenthesisClose {
                continue
            }
            let expression = try parseExpression()
            if expression.type != "Bool" {
                throw Error.unexpectedExpression(expectedType: "Bool", got: expression.type ?? "")
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
    
    private func parseCondition(rec: Bool = true) throws -> Condition {
        let expr1 = try self.parseExpression(condition: rec)
        let op = try self.parseBoolOperator()
        let expr2 = try self.parseExpression(condition: rec)
        return Condition(expr1: expr1, operatorT: op, expr2: expr2)
    }
    
    private func parseExpression(condition: Bool = true) throws -> Expression {
        if let this = self.iteratedElement(), let next = self.peekedElement(), condition, this.type == .identifier {
            switch next.type {
            case .equal, .notEqual, .greater, .greaterEqual, .less, .lessEqual:
                return .condition(try self.parseCondition(rec: false))
            default: break
            }
        }
        
        if let literal = try? self.parseLiteral() {
            return .literal(literal)
        } else if let identifier = try? self.parseIdentifier() {
            return .identifier(identifier)
        }
        throw Error.unimplemented
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
