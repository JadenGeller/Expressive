//
//  Scope.swift
//  Interpreter
//
//  Created by Jaden Geller on 11/20/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

public class Environment {
    private let parent: Environment?
    private var bindings: [String : Value] = [:]
    
    internal init(parent: Environment? = nil) {
        self.parent = parent
    }
    
    internal func declare(identifier identifier: String, value: Value? = nil) {
        assert(bindings[identifier] == nil)
        if let value = value {
            bindings[identifier] = value
        } else {
            bindings[identifier] = Value.Void
        }
    }
    
    internal subscript(identifier: String) -> Value {
        get {
            return bindings[identifier] ?? parent![identifier]
        }
        set {
            if bindings[identifier] != nil {
                bindings[identifier] = newValue
            } else {
                parent![identifier] = newValue
            }
        }
    }
}
