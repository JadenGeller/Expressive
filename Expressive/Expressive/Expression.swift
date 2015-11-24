//
//  Expression.swift
//  Interpreter
//
//  Created by Jaden Geller on 11/20/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

indirect public enum Expression {
    case Return(Value)
    case Lookup([String])
    case Assign(identifiers: [String], value: Expression)
    case Capture(Lambda.Implementation)
    case Invoke(lambda: Expression, argument: Expression)
    case Sequence([Expression])
    
    public static func MultiArgInvoke(lambda lambda: Expression, arguments: [Expression]) -> Expression {
        if arguments.count == 1 {
            return .Invoke(lambda: lambda, argument: arguments.first!)
        } else {
            return .Invoke(
                lambda: MultiArgInvoke(lambda: lambda, arguments: Array(arguments.dropLast())),
                argument: arguments.last!
            )
        }
    }
}

extension Environment {
    private func lookup<S: SequenceType where S.Generator.Element == String>(identifiers: S) -> Environment {
        return identifiers.reduce(self) { environment, identifier in
            environment[identifier].getEnvironment()
        }
    }
}

extension Expression {
    internal func evaluate(environment: Environment) -> Value {
        switch self {
        case .Return(let value):
            return value
        case .Lookup(let identifiers):
            return environment.lookup(identifiers.dropLast())[identifiers.last!]
        case .Assign(let identifiers, let value):
            environment.lookup(identifiers.dropLast())[identifiers.last!] = value.evaluate(environment)
            return Value.Void
        case .Capture(let implementation):
            return Value.Builtin(Lambda(implementation: implementation, environment: environment))
        case .Invoke(let lambda, let argument):
            let lambda = lambda.evaluate(environment).getBuiltin(Lambda)
            return lambda.invoke(argument.evaluate(environment))
        case .Sequence(let actions):
            actions.dropLast().forEach { $0.evaluate(environment) }
            return actions.last!.evaluate(environment)
        }
    }
}
