//
//  Scope.swift
//  Interpreter
//
//  Created by Jaden Geller on 11/16/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

public class Program {
    let globalEnvironment = Environment.standardGlobalEnvironment()
    
    public init(declarations: [String : Expression]) {
        for (identifier, expression) in declarations {
            globalEnvironment.declare(identifier: identifier, value: expression.evaluate(globalEnvironment))
        }
    }
    
    public func run() {
        let main = globalEnvironment["global.main.Void:Void"].getBuiltin(Lambda)
        main.invoke(Value.Void)
    }
}

extension Environment {
    private static func standardGlobalEnvironment() -> Environment {
        let global = Environment()
        
        // print :: String -> Void
        global.declare(identifier: "global.print.String:Void", value: .Builtin(Lambda { _, value in
            print(value.getBuiltin(String))
            return Value.Void
        }))
        
        // concat :: String -> String -> String
        global.declare(identifier: "global.concat.String:String:String", value: .Builtin(Lambda(argumentNames: ["lhs", "rhs"]) { environment in
            return .Builtin(environment["lhs"].getBuiltin(String) + environment["rhs"].getBuiltin(String))
        }))
        
        // print :: Int -> Void
        global.declare(identifier: "global.print.Int:Void", value: .Builtin(Lambda { _, value in
            print(value.getBuiltin(Int))
            return Value.Void
        }))
        
        // negate :: Int -> Int
        global.declare(identifier: "global.negate.Int:Int", value: .Builtin(Lambda { _, value in
            return Value.Builtin(-value.getBuiltin(Int))
        }))
        
        // add :: Int -> Int -> Int
        global.declare(identifier: "global.add.Int:Int:Int", value: .Builtin(Lambda(argumentNames: ["lhs", "rhs"]) { environment in
            return .Builtin(environment["lhs"].getBuiltin(Int) + environment["rhs"].getBuiltin(Int))
        }))
        
        return global
    }
}
