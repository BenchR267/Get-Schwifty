//
//  AST.swift
//  WWDC
//
//  Created by Benjamin Herzog on 01.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import Foundation

struct Program {
    var statements = [Statement]()
}

enum Statement {
    case declaration(Declaration), expression(Expression), controlStructure
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
    var type: String?
}

enum Expression {
    case literal(Token)
}
