//
//  ExpressiveTests.swift
//  ExpressiveTests
//
//  Created by Jaden Geller on 11/21/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

import XCTest
@testable import Expressive

class ExpressiveTests: XCTestCase {
    
    // V -> Void
    func extract<V>(action: V -> ()) -> Expression {
        return Expression.Capture(Lambda.Implementation.Builtin { _, value in
            action(value.getBuiltin(V))
            return .Return(Value.Void)
        })
    }
    
    func testCurriedAdd() {
        var value: Int?
      
        Program(declarations: [
            // main :: Void -> Void = print (add (negate 100) 3)
            "global.main.Void_Void" : .Capture(.Derived(argumentName: "_", declarations: [], value:
                .Invoke(lambda: extract { value = $0 as Int }, argument:
                    .Invoke(
                        lambda: .Invoke(lambda: .Lookup(["global.add.Int_Int_Int"]), argument:
                            .Invoke(lambda: .Lookup(["global.negate.Int_Int"]), argument:
                                .Return(100)
                            )
                        ),
                        argument: .Return(3)
                    )
                )
            ))
        ]).run()
        
        XCTAssertEqual(-97, value)
    }
    
    func testGenerator() {
        var values: [Int] = []
        let append = extract { values.append($0) }
        
        Program(declarations: [
            // generateFrom :: Int -> () -> Int = lambda x (lambda _ (sequence (assign x (add x 1)) x))
            "global.generateFrom.Int_Void_Int" : .Capture(.Derived(argumentName: "x", declarations: [], value:
                .Capture(.Derived(argumentName: "_", declarations: [], value: .Sequence([
                    .Assign(identifiers: ["x"], value:
                        .Invoke(
                            lambda: .Invoke(lambda: .Lookup(["global.add.Int_Int_Int"]), argument:
                                .Lookup(["x"])
                            ),
                            argument: .Return(1)
                        )
                    ),
                    .Lookup(["x"])
                ])))
            )),
            
            // main :: _ -> _ = lambda _ (sequence (assign next (generateFrom 7)) (print (next ())) (print (next ())) (print (next ())))
            "global.main.Void_Void" : .Capture(.Derived(argumentName: "_", declarations: ["next"], value:
                .Sequence([
                    .Assign(identifiers: ["next"], value:
                        .Invoke(lambda: .Lookup(["global.generateFrom.Int_Void_Int"]), argument: .Return(7))
                    ),
                    .Invoke(lambda: append, argument: .Invoke(lambda: .Lookup(["next"]), argument: .Return(Value.Void))),
                    .Invoke(lambda: append, argument: .Invoke(lambda: .Lookup(["next"]), argument: .Return(Value.Void))),
                    .Invoke(lambda: append, argument: .Invoke(lambda: .Lookup(["next"]), argument: .Return(Value.Void)))
                ])
            ))
        ]).run()
        
        XCTAssertEqual([8, 9, 10], values)
    }
    
    func testRecursion() {
        var result: Int!
        
        Program(declarations: [
            // factorial :: Int -> Int = lambda x (if (equals x 0) (lambda _ 1) (lambda _ (multiply x (factorial (add x (negate 1))))))
            "global.factorial.Int_Int" : .Capture(.Derived(argumentName: "x", declarations: [], value: Expression.MultiArgInvoke(
                lambda: .Lookup(["global.if.Bool_[Void.T]_[Void.T]_T"]),
                arguments: [
                    .MultiArgInvoke(lambda: .Lookup(["global.equals.Int_Int_Bool"]), arguments: [.Lookup(["x"]), .Return(.Builtin(0))]),
                    .Capture(.Derived(argumentName: "_", declarations: [], value: .Return(.Builtin(1)))),
                    .Capture(.Derived(argumentName: "_", declarations: [], value: .MultiArgInvoke(
                        lambda: .Lookup(["global.multiply.Int_Int_Int"]),
                        arguments: [
                            .Lookup(["x"]),
                            .Invoke(
                                lambda: .Lookup(["global.factorial.Int_Int"]),
                                argument: .MultiArgInvoke(
                                    lambda: .Lookup(["global.add.Int_Int_Int"]),
                                    arguments: [
                                        .Lookup(["x"]),
                                        .Invoke(lambda: .Lookup(["global.negate.Int_Int"]), argument: .Return(.Builtin(1)))
                                    ]
                                )
                            )
                        ]
                    )))
                ]
            ))),
            
            // main :: _ -> _ = lambda _ (print (factorial 5))
            "global.main.Void_Void" : .Capture(.Derived(argumentName: "_", declarations: [], value:
                .Invoke(lambda: extract{ result = $0 as Int }, argument: .Invoke(lambda: .Lookup(["global.factorial.Int_Int"]), argument: .Return(.Builtin(5))))
            ))
        ]).run()
        
        XCTAssertEqual(120, result)
    }
    
    func testLoop() {
        var count = 0
        
        Program(declarations: [
            // main :: _ -> _ = lambda _ (sequence (assign x 10) (while (lambda _ (not (equal x 0))) (lambda _ (sequence (assign x (add x (negate 1))) (print ())))))
            "global.main.Void_Void" : .Capture(.Derived(argumentName: "_", declarations: ["x"], value:
                .Sequence([
                    .Assign(identifiers: ["x"], value: .Return(10)),
                    .MultiArgInvoke(lambda: .Lookup(["global.while.[Void_Bool]_[Void_T]_Void"]), arguments: [
                        .Capture(.Derived(argumentName: "_", declarations: [], value:
                            .Invoke(lambda: .Lookup(["global.not.Bool_Bool"]), argument:
                                .MultiArgInvoke(lambda: .Lookup(["global.equals.Int_Int_Bool"]), arguments: [
                                    .Lookup(["x"]),
                                    .Return(0)
                                ])
                            )
                        )),
                        .Capture(.Derived(argumentName: "_", declarations: [], value: .Sequence([
                            .Assign(identifiers: ["x"], value: .MultiArgInvoke(lambda: .Lookup(["global.add.Int_Int_Int"]), arguments: [
                                .Lookup(["x"]),
                                .Invoke(lambda: .Lookup(["global.negate.Int_Int"]), argument: .Return(1))
                            ])),
                            .Invoke(lambda: extract{ count += 1 }, argument: .Return(Value.Void))
                        ])))
                    ])
                ])
            ))
        ]).run()
        
        XCTAssertEqual(10, count)
    }
    
    func testRecord() {
        var greeting: String?
        
        Program(declarations: [
            // makePerson :: String -> Int -> Person = lambda name (lambda age (sequence (declare person (record name age)) (assign (field person name) name) (assign (field person age) age)))
            "global.makePerson.String_Int_Person" : .Capture(.Derived(argumentName: "name", declarations: [], value:
                .Capture(.Derived(argumentName: "age", declarations: ["person"], value: .Sequence([
                    .Assign(identifiers: ["person"], value: Expression.Return(Value.MakeRecord(["name", "age"]))),
                    .Assign(identifiers: ["person", "name"], value: .Lookup(["name"])),
                    .Assign(identifiers: ["person", "age"], value: .Lookup(["age"])),
                    .Lookup(["person"])
                ])))
            )),
            
            "Person.greet.Void_String" : .Capture(.Derived(argumentName: "self", declarations: [], value:
                .MultiArgInvoke(
                    lambda: .Lookup(["global.concat.String_String_String"]),
                    arguments: [
                        .MultiArgInvoke(
                            lambda: .Lookup(["global.concat.String_String_String"]),
                            arguments: [.Return("Hi, my name is "), .Lookup(["self", "name"])]
                        ),
                        .Return("!!!")
                    ]
                )
            )),
            
            // main :: _ -> _ = lambda _ (sequence (assign jaden (makePerson "Jayden Geller" 20)) (assign (field jaden name) "Jaden Geller") (print ((field jaden greet) ())))
            "global.main.Void_Void" : .Capture(.Derived(argumentName: "_", declarations: ["jaden"], value:
                .Sequence([
                    .Assign(identifiers: ["jaden"], value: .MultiArgInvoke(
                        lambda: .Lookup(["global.makePerson.String_Int_Person"]),
                        
                        
                        arguments: [.Return("Jayden Geller"), .Return(20)]
                    )),
                    .Assign(identifiers: ["jaden", "name"], value: .Return("Jaden Geller")),
                    .Invoke(lambda: extract { greeting = $0 as String }, argument: .Invoke(lambda: .Lookup(["Person.greet.Void_String"]), argument: .Lookup(["jaden"])))
                ])
            ))
        ]).run()
        
        XCTAssertEqual("Hi, my name is Jaden Geller!!!", greeting)
    }
}
