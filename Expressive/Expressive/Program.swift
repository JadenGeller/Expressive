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
            return .Return(Value.Void)
        }))
        
        // concat :: String -> String -> String
        global.declare(identifier: "global.concat.String:String:String", value: .Builtin(Lambda(argumentNames: ["lhs", "rhs"]) { environment in
            return .Return(.Builtin(environment["lhs"].getBuiltin(String) + environment["rhs"].getBuiltin(String)))
        }))
        
        // print :: Int -> Void
        global.declare(identifier: "global.print.Int:Void", value: .Builtin(Lambda { _, value in
            print(value.getBuiltin(Int))
            return .Return(Value.Void)
        }))
        
        // negate :: Int -> Int
        global.declare(identifier: "global.negate.Int:Int", value: .Builtin(Lambda { _, value in
            return .Return(Value.Builtin(-value.getBuiltin(Int)))
        }))
        
        // add :: Int -> Int -> Int
        global.declare(identifier: "global.add.Int:Int:Int", value: .Builtin(Lambda(argumentNames: ["lhs", "rhs"]) { environment in
            return .Return(.Builtin(environment["lhs"].getBuiltin(Int) + environment["rhs"].getBuiltin(Int)))
        }))
        
        // multiply :: Int -> Int -> Int
        global.declare(identifier: "global.multiply.Int:Int:Int", value: .Builtin(Lambda(argumentNames: ["lhs", "rhs"]) { environment in
            return .Return(.Builtin(environment["lhs"].getBuiltin(Int) * environment["rhs"].getBuiltin(Int)))
        }))
        
        // equals :: Int -> Int -> Int
        global.declare(identifier: "global.equals.Int:Int:Bool", value: .Builtin(Lambda(argumentNames: ["lhs", "rhs"]) { environment in
            return .Return(.Builtin(environment["lhs"].getBuiltin(Int) == environment["rhs"].getBuiltin(Int)))
        }))
        
        // if :: Bool -> (() -> T) -> (() -> T) -> T
        global.declare(identifier: "global.if.Bool:T:T:T", value: .Builtin(Lambda(argumentNames: ["condition", "trueCapture", "falseCapture"]) { environment in
            return .Invoke(
                lambda: .Return(environment["condition"].getBuiltin(Bool) ? environment["trueCapture"] : environment["falseCapture"]),
                argument: .Return(Value.Void)
            )
        }))
        // Note that if all types are reference types behind the scenes, we don't need duplicate `condition` implementations.
        
        return global
    }
}
