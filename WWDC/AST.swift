//
//  AST.swift
//  WWDC
//
//  Created by Benjamin Herzog on 01.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import Foundation

struct Program {
    var scope: Scope
}

struct Scope {
    var statements = [Statement]()
}

enum Statement {
    case declaration(Declaration), controlStructure(ControlStructure), expression(Expression)
}

enum Declaration {
    case function(FunctionDecl), variable(VariableDecl), constant(LetDecl)
}

struct FunctionDecl {
    var name: String
    var parameters: [ParameterDecl]
    var returnType: String
    var body: FunctionBody
}

struct FunctionBody {
    var statements: [Statement]
    var returnExpr: Expression?
}

struct VariableDecl {
    var parameter: ParameterDecl
    var expression: Expression?
}

struct LetDecl {
    var parameter: ParameterDecl
    var expression: Expression?
}

struct ParameterDecl {
    var name: String
    var type: String
}

enum ControlStructure {
    case ifS(If), forS(For), whileS(While)
}

struct If {
    // will be evaluated in order (if, else if, ...)
    var conditions: [(MultipleCondition, Scope)]
    var elseS: Scope?
}

struct MultipleCondition {
    var conditions: [Expression]
    var operators: [Token]
}

struct Condition {
    var expr1: Expression
    var operatorT: Token
    var expr2: Expression
}

struct For {
    // TODO
}

struct While {
    var expression: Expression
    var scope: Scope
}

struct Call {
    var name: String
    var parameters: [Expression]
}

struct MultipleCalculation {
    var expressions: [Expression]
    var operators: [Token]
}

indirect enum Expression {
    case literal(Token)
    case identifier(Token)
    case condition(Condition)
    case call(Call)
    case calculation(MultipleCalculation)
    
    var type: String? {
        switch self {
        case .literal(let token):
            switch token.type {
            case .literal(.String(_)):
                return "String"
            case .literal(.Integer(_)):
                return "Int"
            default:
                return nil
            }
        case .identifier(let token):
            return "" // TODO (ASTContext)
        case .call(let call):
            return "" // TODO (ASTContext)
        case .calculation(let calc):
            return "Int"
        case .condition(_):
            return "Bool"
        }
    }
}
