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
        var statements = [Statement]()
        while let _ = iteratedElement() {
            let statement = try parseStatement()
            statements.append(statement)
        }
        return Program(statements: statements)
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
        let name = try self.parseIdentifier()
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
            returnType = try self.parseIdentifier()
        }
        try self.parse(.curlyBracketOpen)
        let body = try self.parseFunctionBody()
        try self.parse(.curlyBracketClose)
        return FunctionDecl(name: name, parameters: parameters, returnType: returnType, body: body)
    }
    
    private func parseFunctionBody() throws -> FunctionBody {
        var statements = [Statement]()
        while let _ = iteratedElement() {
            let statement = try parseStatement()
            statements.append(statement)
        }
        throw Error.unimplemented
    }
    
    private func parseVariableDecl() throws -> VariableDecl {
        let param = try self.parseParameterDecl()
        var expr: Expression? = nil
        if let next = self.iteratedElement(), next.type == .assign {
            try self.parse(.assign)
            expr = try self.parseExpression()
        }
        return VariableDecl(parameter: param, expression: expr)
    }
    
    private func parseLetDecl() throws -> LetDecl {
        let param = try self.parseParameterDecl()
        var expr: Expression? = nil
        if let next = self.iteratedElement(), next.type == .assign {
            try self.parse(.assign)
            expr = try self.parseExpression()
        }
        return LetDecl(parameter: param, expression: expr)
    }
    
    private func parseParameterDecl() throws -> ParameterDecl {
        let identifier = try self.parseIdentifier()
        var type: String? = nil
        if let next = self.iteratedElement(), next.type == .colon {
            try self.parse(.colon)
            type = try self.parseIdentifier()
        }
        return ParameterDecl(name: identifier, type: type)
    }
    
    private func parseExpression() throws -> Expression {
        let literal = try self.parseLiteral()
        return .literal(literal)
    }
    
    private func parseLiteral() throws -> Token {
        guard let current = self.iteratedElement() else {
            throw Error.unexpectedEOF
        }
        if case .literal(_) = current.type {
            self.nextToken()
            return current
        }
        throw Error.unexpectedType(expected: .literal(.Integer(0)), got: current)
    }
    
    private func parseIdentifier() throws -> String {
        let raw = self.iteratedElement()?.raw
        try self.parse(.identifier)
        return raw!
    }
    
    private func parseKeyword() throws -> String {
        let raw = self.iteratedElement()?.raw
        try self.parse(.keyword)
        return raw!
    }
    
}
