//
//  Generator.swift
//  WWDC
//
//  Created by Benjamin Herzog on 01.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import Foundation

public class Generator {
    
    init() {}
    
    public func generate(program: Program) -> String {
        return generate(program.scope)
    }
    
    private func generate(_ a: Scope) -> String {
        return a.statements.map(generate).joined(separator: "\n")
    }
    
    private func generate(_ a: Statement) -> String {
        let o: String
        switch a {
        case .declaration(let decl):
            o = generate(decl)
        case .controlStructure(let c):
            o = generate(c)
        case .expression(let e):
            o = generate(e)
        case .assignment(let a):
            o = generate(a)
        case .returnE(let e):
            o = "return " + (e.map(generate) ?? "")
        }
        return o + ";\n"
    }
    
    private func generate(_ a: Assignment) -> String {
        return "\(a.identifer.raw) = \(generate(a.expression))"
    }
    
    private func generate(_ a: Declaration) -> String {
        switch a {
        case .constant(let l):
            return generate(l)
        case .variable(let v):
            return generate(v)
        case .function(let f):
            return generate(f)
        }
    }
    
    private func generate(_ a: LetDecl) -> String {
        var o = "const \(a.parameter.name)"
        if let e = a.expression {
            o.append(" = \(generate(e))")
        }
        o.append("")
        return o
    }
    
    private func generate(_ f: FunctionDecl) -> String {
        var o = "function \(f.name)("
        o.append(f.parameters.map(generate).joined(separator: ", "))
        o.append(") {\n")
        o.append(generate(f.body))
        o.append("}\n")
        return o
    }
    
    private func generate(_ a: ParameterDecl) -> String {
        return a.name
    }
    
    private func generate(_ a: FunctionBody) -> String {
        return a.statements.map(generate).joined(separator: "\n")
    }
    
    private func generate(_ a: VariableDecl) -> String {
        var o = "var \(a.parameter.name)"
        if let e = a.expression {
            o.append(" = \(generate(e))")
        }
        return o
    }
    
    private func generate(_ a: Call) -> String {
        var o = "\(a.name)("
        o.append(a.parameters.map(generate).joined(separator: ", "))
        o.append(")")
        return o
    }
    
    private func generate(_ a: Condition) -> String {
        return "\(generate(a.expr1)) \(a.operatorT.raw) \(generate(a.expr2))"
    }
    
    private func generate(_ a: MultipleCalculation) -> String {
        var o = ""
        for (i, e) in a.expressions.enumerated() {
            o.append(generate(e))
            if i < a.operators.count {
                o.append(" ")
                o.append(a.operators[i])
                o.append(" ")
            }
        }
        return o
    }
    
    private func generate(_ a: ControlStructure) -> String {
        switch a {
        case .ifS(let i):
            return generate(i)
        case .whileS(let w):
            return generate(w)
        default:
            return "// unimplemented \(a)"
        }
    }
    
    private func generate(_ a: If) -> String {
        var conditions = a.conditions
        var o = "if ("
        let ifC = conditions.removeFirst()
        o.append(generate(ifC.0))
        o.append(") {\n")
        o.append(generate(ifC.1))
        o.append("\n}\n")
        for c in conditions {
            o.append("else if (")
            o.append(generate(c.0))
            o.append(") {\n")
            o.append(generate(c.1))
            o.append("\n}\n")
        }
        if let el = a.elseS {
            o.append("else {\n")
            o.append(generate(el))
            o.append("\n}")
        }
        return o
    }
    
    private func generate(_ a: MultipleCondition) -> String {
        var o = ""
        for (i, e) in a.conditions.enumerated() {
            o.append(generate(e))
            if i < a.operators.count {
                o.append(" ")
                o.append(a.operators[i].raw)
                o.append(" ")
            }
        }
        return o
    }
    
    private func generate(_ a: While) -> String {
        return "while (\(generate(a.expression))) {\n\(generate(a.scope))\n}"
    }
    
    private func generate(_ a: Expression) -> String {
        switch a {
        case .literal(let t):
            return t.raw
        case .call(let c):
            return generate(c)
        case .condition(let c):
            return generate(c)
        case .identifier(let t):
            return t.raw
        case .calculation(let c):
            return generate(c)
        }
    }
    
}
