//
//  Lambda.swift
//  Interpreter
//
//  Created by Jaden Geller on 11/20/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

public class Lambda {
    public enum Implementation {
        case Derived(argumentName: String, declarations: [String], value: Expression)
        case Builtin((Environment, Value) -> Expression)
        
        public static func MultiArgBuiltin(argumentNames argumentNames: [String], builtin: Environment -> Expression) -> Implementation {
            if argumentNames.count == 1 {
                return .Derived(argumentName: argumentNames.first!, declarations: [], value:
                    .Invoke(lambda: .Capture(Lambda.Implementation.Builtin { (environment, value) in builtin(environment) }), argument: .Return(.Void))
                )
            } else {
                return .Derived(argumentName: argumentNames.first!, declarations: [], value:
                    .Capture(MultiArgBuiltin(argumentNames: Array(argumentNames.dropFirst()), builtin: builtin))
                )
            }
        }
        
        public static func MultiArgVirtual(argumentNames argumentNames: [String], declarations: [String], value: Expression) -> Implementation {
            if argumentNames.count == 1 {
                return .Derived(argumentName: argumentNames.first!, declarations: declarations, value: value)
            } else {
                return .Derived(argumentName: argumentNames.first!, declarations: [], value:
                    .Capture(MultiArgVirtual(argumentNames: Array(argumentNames.dropFirst()), declarations: declarations, value: value))
                )
            }
        }
    }

    private let implementation: Implementation
    private let environment: Environment?
    
    public init(implementation: Implementation, environment: Environment? = nil) {
        self.implementation = implementation
        self.environment = environment
    }
    
    public convenience init(builtin: (Environment, Value) -> Expression) {
        self.init(implementation: .Builtin(builtin))
    }
    
    public convenience init(argumentNames: [String], builtin: Environment -> Expression) {
        self.init(implementation: .MultiArgBuiltin(argumentNames: argumentNames, builtin: builtin))
    }
}

extension Lambda {
    internal func invoke(argument: Value) -> Value {
        let environment = Environment(parent: self.environment)
        switch implementation {
        case .Derived(let argumentName, let declarations, let value):
            declarations.forEach { environment.declare(identifier: $0) }
            environment.declare(identifier: argumentName, value: argument)
            return value.evaluate(environment)
        case .Builtin(let function):
            return function(environment, argument).evaluate(environment)
        }
    }
}
