//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Riyad Shauk on 1/9/17.
//  Copyright © 2017 Riyad Shauk. All rights reserved.
//  Code taken largely from Stanford's CS 193p Swift Programming course; I programmed and commented this while going through the tutorials.
//  FYI: This is meant to be viewed in Xcode, as Xcode automatically line-wraps (in case you were wondering about the very long comments).

import Foundation
import GameKit // for random-number generation with seeding

/* This function is defined here for pedagogical purposes, to execmplify a more modularized yet still functional approach to that taken in the operations dictionary for mapping the other binary operation symbols to functions. */
private func multiply(op1: Double, op2: Double) -> Double {
    return op1 * op2
}

private func isPrime(n: Double) -> Double {
    // see http://stackoverflow.com/questions/1801391/what-is-the-best-algorithm-for-checking-if-a-number-is-prime
    /* "It uses the fact that a prime (except 2 and 3) is of form 6k - 1 or 6k + 1 and looks only at divisors of this form." (from SO) */
    if n - Double(Int(n)) != 0 { // number is not natural
        return 0
    } else if n <= 1 { // according to this def, http://www.askamathematician.com/2010/01/q-why-is-the-number-1-not-considered-a-prime-number/
        return 0
    }else if n == 2 { // by def
        return 1
    } else if n == 3 { // by def
        return 1
    } else if n.truncatingRemainder(dividingBy: 2) == 0 {
        return 0
    } else if n.truncatingRemainder(dividingBy: 3) == 0 {
        return 0
    }
    var i = 5.0
    var w = 2.0
    while i*i <= n {
        if n.truncatingRemainder(dividingBy: i) == 0 {
            return 0
        }
        i += w
        w = 6 - w
    }
    return 1
}
var isModulus = false
private func modulo(op1: Double, op2: Double) -> Double {
    isModulus = true
    return op1.truncatingRemainder(dividingBy: op2)
}

//private typealias Modulo = (Double, Double) -> Double

private func rand() -> Double {
    // see http://stackoverflow.com/questions/38679670/swift-seeding-arc4random-uniform-or-alternative?rq=1
    let rs = GKMersenneTwisterRandomSource()
    let time = Int(NSDate().timeIntervalSinceReferenceDate) // see http://stackoverflow.com/questions/25895081/how-does-one-seed-the-random-number-generator-in-swift
    rs.seed = UInt64(Int(arc4random_uniform(UInt32(time))))
    let rd = GKRandomDistribution(randomSource: rs, lowestValue: 0, highestValue: 1000)
    return Double(rd.nextUniform())
}

struct Stack<Element> {
    private var items = [Element]()
    var itemCount = 0
    mutating func push(_ item: Element) {
        itemCount += 1
        items.append(item)
    }
    mutating func pop() -> Element? {
        if itemCount > 0 {
            itemCount -= 1
            return items.removeLast()
        } else {
            return nil
        }
    }
    func peek() -> Element? {
        if itemCount > 0 {
            return items.last
        } else {
            return nil
        }
    }
}

class calculatorBrain {
    
    func clearOp() -> () {
        acc = 0.0
        pending = nil
        description = ""
        isPartialResult = false
        operationsStack = Stack<Operation>()
    }
    
    func doubleToString(d: Double) -> String {
        if d - Double(Int(d)) != 0 {
            return String(d)
        } else {
            return String(Int(d))
        }
    }
    
    /* an accumulator of the most recent number represented on the main calculator display */
    private var acc = 0.0
    var lastDescription = "" // arguably hacky way to get around correctly setting the description in an edge case when using a unary operator while the user is in the middle of typing (and setOperand is called)
    
    private var nonScalarOperationMustFollowToKeepCurCalculationActive = false
    
    private var lastButtonWasADigit = false
    
    /* Part of model API, called in ViewController */
    func setOperand(operand: Double) {
        acc = operand
        lastButtonWasADigit = true
        lastDescription = description
        if nonScalarOperationMustFollowToKeepCurCalculationActive {
            lastDescription = description
            description = ""
        }
        nonScalarOperationMustFollowToKeepCurCalculationActive = false
        if acc - Double(Int(acc)) != 0 {
            description = description + String(acc)
        } else {
            description = description + String(Int(acc))
        }
    }
    
    /* A dictionary that takes an operation symbol, represented by a String, and outputs an operation, which is a function mapped to an abstract type representation of the operation the function represents. */
    private lazy var operations: Dictionary<String,Operation> = [
        // add modulo operator
        // add isPrime
        // Celcius / Fahrenheit
        // k/h / mi/h
        // grams / ounces
        "mod" : Operation.BinaryOperation(modulo),
        "del" : Operation.VoidOperation({}),
        "p?" : Operation.UnaryOperation(isPrime),
        "C -> F" : Operation.UnaryOperation({ $0 * 1.8 + 32 }),
        "F -> C" : Operation.UnaryOperation({ ($0 - 32) / 1.8 }),
        "MPH to KPH" : Operation.UnaryOperation({ $0 * 1.609344 }),
        "KPH to MPH" : Operation.UnaryOperation({ $0 * 0.621371 }),
        "g -> oz" : Operation.UnaryOperation({ $0 * 0.035274 }),
        "oz -> g" : Operation.UnaryOperation({ $0 * 28.3495 }),
        /* http://stackoverflow.com/questions/39172136/random-double-number-in-swift-between-0-and-1 */
//        "rand" : Operation.Constant(Double(arc4random_uniform(10000000))/100000001),
        "rand" : Operation.VoidDoubleOperation(rand),
        "c" : Operation.VoidOperation(self.clearOp),
        "π" : Operation.Constant(M_PI),
        "℮" : Operation.Constant(M_E),
        "±": Operation.UnaryOperation({ -1*$0 }),
        "√" : Operation.UnaryOperation(sqrt),
        "cos" : Operation.UnaryOperation(cos),
        /* can pass in a defined function (e.g., see "multiply" defined in this file). */
        "×" : Operation.BinaryOperation(multiply),
        /* In Swift, functions are closures, so just provide a function inline, as a closure, and Swift infers that the closure is meant to be a function, from the context. */
        "÷" : Operation.BinaryOperation({ (op1: Double, op2: Double) -> Double in return op1 / op2 }),
        /* But then Swift can infer parameter and return types too */
        "+" : Operation.BinaryOperation({ (op1, op2) in return op1 + op2 }),
        /* Swift uses $0,$1,... as first,second,... parameters of function closure... And it can also infer that the expression should be returned, hence the explanation of the syntax behind writing a simple expression to mean a function closure. Super awesome/cool stuff, ehm! */
        "−" : Operation.BinaryOperation({ $0 - $1 }),
        "=" : Operation.Equals
    ]
    
    /* specifies (abstract) types of operations */
    private enum Operation {
        case VoidOperation(() -> ())
        case VoidDoubleOperation(() -> Double)
        case Constant(Double)
        case UnaryOperation((Double) -> Double)
        case BinaryOperation((Double, Double) -> Double)
        case Equals
    }
    
    var operationNotRecognized = false
    private var operationsStack = Stack<Operation>()
    
    /* takes an operand, stuff happens, and acc is updated. This is an API to be called from the controller. */
    func performOperation(symbol: String) {
        /* if the symbol maps to a functionality, in the operations dict... */
        if let operation = operations[symbol] {
            if description == "" { // should set description to "0"
                description = doubleToString(d: acc)
                lastButtonWasADigit = true
            }
            operationNotRecognized = false
            if nonScalarOperationMustFollowToKeepCurCalculationActive {
                switch operation {
                case .VoidDoubleOperation(_):
                    break
                case .Constant(_):
                    break
                default:
                    nonScalarOperationMustFollowToKeepCurCalculationActive = false
                }
                if nonScalarOperationMustFollowToKeepCurCalculationActive {
                    lastDescription = description
                    description = ""
                }
            }
            var descriptionUpdated = false
            switch operation {
            case .VoidOperation(let f):
                f()
            case .VoidDoubleOperation(let f):
                acc = f()
                nonScalarOperationMustFollowToKeepCurCalculationActive = true
                if lastButtonWasADigit {
                    lastDescription = description
                    description = ""
                }
            case .Constant(let value):
                acc = value
                nonScalarOperationMustFollowToKeepCurCalculationActive = true
                if lastButtonWasADigit {
                    lastDescription = description
                    description = ""
                }
            case .UnaryOperation(let f):
                if !lastButtonWasADigit && (operationsStack.itemCount == 0 || operationsStack.itemCount == 1) {
                    description = "0"
                }
                if !isPartialResult {
                    description = symbol + "(" + description + ")"
                } else {
                    description = lastDescription + symbol + "(" + doubleToString(d: acc) + ")"
                }
                descriptionUpdated = true
                nonScalarOperationMustFollowToKeepCurCalculationActive = true
                acc = f(acc)
            case .BinaryOperation(let f):
                executePendingBinaryOperation()
                /* At this point, acc is either updated by executePendingBinaryOperation or it remains the same, but the user has only typed in the first operand of the currently pending binary operation, so we set pending with the binary operation functionality defined in f (that was taken from the symbol-function dictionary), and a first operand of acc. */
                pending = PendingBinaryOperationInfo(binaryFunction: f, firstOperand: acc)
                if pending != nil {
                    isPartialResult = true
                } else {
                    isPartialResult = false
                }
            case .Equals:
                /* The Equals symbol only needs to be typed after a binary operation, followed by the acc operand (AKA a pending binary operation). Typing Equals ends the chain of pending binary operations and simply calculates the pending binary operation, if it exists, as done here. */
                executePendingBinaryOperation()
                nonScalarOperationMustFollowToKeepCurCalculationActive = true
            }
            if let lastSymbol = operationsStack.peek() {
                if !lastButtonWasADigit {
                    switch lastSymbol {
                    case .BinaryOperation(_):
                        var offset = 1
                        if isModulus {
                            offset = 3
                        }
                        switch operation {
                        case .VoidDoubleOperation(_):
                            isPartialResult = false
                            break
                        case .Constant(_):
                            isPartialResult = false
                            break
                        default:
                            // i.e.: "7+= --> 7+7=14", "7++1 --> 7+7+1=15"
                            description = description + String(description.characters.dropLast(offset))
                        }
                    default:
                        break
                    }
                }
            }
            if symbol != "=" && !descriptionUpdated && symbol != "c" && symbol != "del" {
                description = description + symbol
                descriptionUpdated = true
            }
            operationsStack.push(operation)
        } else {
            operationNotRecognized = true
        }
        lastButtonWasADigit = false
        isModulus = false
    }
    
    /* If there was a pending binary operation (one that could not be complete because the second operand was not available), then apply the binary function using the first operand (previously entered) and the current acc (which may have been set just before the user touched a symbol, as seen in ViewController.performOperation when brain.setOperand is called) as the second operand. */
    private func executePendingBinaryOperation() {
        if pending != nil { // Optional types can be nil
            acc = pending!.binaryFunction(pending!.firstOperand, acc)
            pending = nil
            isPartialResult = false
        }
    }
    
    /* pending is an Optional type since it represents the state of the calculator when a binary operation is pending (and, naturally, such an operation is not always what is being calculated). */
    private var pending: PendingBinaryOperationInfo?
    
    /* This struct defines a pending binary operation (think similar to a partial application of a binary operation in the functional programming paradigm). */
    private struct PendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
    }
    
    var result: Double {
        get {
            return acc
        } // don't need a setter.
    }
    
    var description = ""
    
    var isPartialResult = false
    
//    private var rightParenStack = Stack<String>()
//    private var leftParenStack = Stack<String>()
//    private func parenPushed() -> () {
//        
//    }
}
