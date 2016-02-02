//
//  Value.swift
//  Interpreter
//
//  Created by Jaden Geller on 11/20/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

public enum Value {
    case Builtin(Any)
    case Record(Environment)
    
    public static var Void: Value {
        return .Builtin(())
    }
    
    internal func getBuiltin<T>(type: T.Type) -> T {
        guard case let .Builtin(value) = self else { fatalError() }
        return value as! T
    }
    
    internal func getEnvironment() -> Environment {
        guard case let .Record(environment) = self else { fatalError() }
        return environment
    }
    
    public static func MakeRecord(fields: [String]) -> Value {
        let environment = Environment()
        fields.forEach { environment.declare(identifier: $0) }
        return .Record(environment)
    }
}

extension Value: IntegerLiteralConvertible {
    public init(integerLiteral value: Int) {
        self = .Builtin(value)
    }
}

extension Value: StringLiteralConvertible {
    public init(stringLiteral value: String) {
        self = .Builtin(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(stringLiteral: value)
    }
    
    public init(unicodeScalarLiteral value: String) {
        self.init(stringLiteral: value)
    }
}

extension Value: FloatLiteralConvertible {
    public init(floatLiteral value: Float) {
        self = .Builtin(value)
    }
}
