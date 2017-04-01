//
//  AST.swift
//  WWDC
//
//  Created by Benjamin Herzog on 01.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import Foundation

public struct Program {
    public var scope: Scope
}

public struct Scope {
    public var statements = [Statement]()
    
    // name: type
    // function parameters: _func_NAME_0, _func_NAME_1, ...
    public var namelist = [String: String]()
}

public enum Statement {
    case declaration(Declaration)
    case controlStructure(ControlStructure)
    case expression(Expression)
    case assignment(Assignment)
}

public struct Assignment {
    public var identifer: Token
    public var expression: Expression
}

public enum Declaration {
    case function(FunctionDecl)
    case variable(VariableDecl)
    case constant(LetDecl)
}

public struct FunctionDecl {
    public var name: String
    public var parameters: [ParameterDecl]
    public var returnType: String
    public var body: FunctionBody
}

public struct FunctionBody {
    public var statements: [Statement]
    public var returnExpr: Expression?
}

public struct VariableDecl {
    public var parameter: ParameterDecl
    public var expression: Expression?
}

public struct LetDecl {
    public var parameter: ParameterDecl
    var expression: Expression?
}

public struct ParameterDecl {
    public var name: String
    public var type: String
}

public enum ControlStructure {
    case ifS(If)
    case forS(For)
    case whileS(While)
}

public struct If {
    // will be evaluated in order (if, else if, ...)
    public var conditions: [(MultipleCondition, Scope)]
    public var elseS: Scope?
}

public struct MultipleCondition {
    public var conditions: [Expression]
    public var operators: [Token]
}

public struct Condition {
    public var expr1: Expression
    public var operatorT: Token
    public var expr2: Expression
}

public struct For {
    // TODO
}

public struct While {
    public var expression: MultipleCondition
    public var scope: Scope
}

public struct Call {
    public var name: String
    public var parameters: [Expression]
}

public struct MultipleCalculation {
    public var expressions: [Expression]
    public var operators: [Token]
}

public indirect enum Expression {
    case literal(Token)
    case identifier(Token)
    case call(Call)
    case condition(Condition)
    case calculation(MultipleCalculation)
    
    public func type(_ namelist: [String: String]) -> String {
        switch self {
        case .literal(let token):
            switch token.type {
            case .literal(.String(_)):
                return "String"
            case .literal(.Integer(_)):
                return "Int"
            case .literal(.Double(_)):
                return "Double"
            default:
                return "Void"
            }
        case .identifier(let token):
            return namelist[token.raw] ?? "Void"
        case .call(let call):
            return namelist[call.name] ?? "Void"
        case .calculation(_):
            return "Int"
        case .condition(_):
            return "Bool"
        }
    }
}
