//
//  ViewController.swift
//  Calculator
//
//  Created by Riyad Shauk on 1/9/17.
//  Copyright © 2017 Riyad Shauk. All rights reserved.
//  Code largely inspired from Stanford's CS 193p Swift Programming course; I programmed and commented this while going through the tutorials.
//  FYI: This is meant to be viewed in Xcode, as Xcode automatically line-wraps (in case you were wondering about the very long comments).
//  @TODO Refactor ViewController to be less coupled, more concise, using CalculatorBrain for more of the logic (like converting doubles to certain string representations...)
//  @TODO Fix the View in Main.storyboard s.t. it properly works in landscape mode on all devices.

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var display: UILabel!
    
    @IBOutlet weak var descriptionOfOperations: UILabel!
 
    var userIsInTheMiddleOfTyping = false
    private func userAlreadyTypedADecimal() -> Bool {
        if (display.text?.contains("."))! {
            return true
        } else {
            return false
        }
    }
    
    private func isZero(z: String) -> Bool {
        if z == "0" || z == "0.0" {
            return true
        } else {
            return false
        }
    }
    
    private func stringToDoubleFormattedString(d: String) -> String {
        if Double(d) == nil || Double(d)!.isNaN {
            return d
        } else if Double(d)! - Double(Int(Double(d)!)) != 0 {
            return d
        } else {
            return String(describing: Int(Double(d)!))
        }
    }
    
    private var boolOperationTouched = false
    
    private func setDisplay(s: String, t: String = "") {
        if isZero(z: display.text!) && !userIsInTheMiddleOfTyping && !userAlreadyTypedADecimal() && s != "." {
            // ensure proper behavior after touching "c"-symbol
            display.text = s + t
        } else if !userAlreadyTypedADecimal() && (isZero(z: s) && isZero(z: t)) {
            // avoid multiple zeros before decimal (0*.)
        } else if !userAlreadyTypedADecimal() && (isZero(z: s) && t == ".") {
            // avoid a zero before decimal (0+.)
            display.text = s + t
        } else if !userAlreadyTypedADecimal() && userIsInTheMiddleOfTyping && (isZero(z: s) && !isZero(z: t)) {
            // avoid numbers starting with zero before a decimal (0+{\d}+.)
            display.text = t
        } else if (display.text == "" || isZero(z: display.text!) || display.text == "." || s == ".") {
            // avoid numbers starting with a decimal. Instead, should be of form (0.*)
            if userIsInTheMiddleOfTyping && t != "." {
                if display.text!.contains("0.") {
                    // display.text == s already contains 0.
                    display.text = s + t
                } else {
                    // first occurence of decimal, so precede with 0
                    display.text = "0." + t
                }
            } else if !userIsInTheMiddleOfTyping && s == "." {
                display.text = "0."
            }
        } else if s != t && (s == "." || t == ".") && !userAlreadyTypedADecimal() {
            display.text = s + t
        } else if t != "." {
            display.text = s + t
        }
        userIsInTheMiddleOfTyping = true
    }

    private var firstDigit = true
    @IBAction private func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle! // ! makes the compiler know digit type is String, not String? (not an Optional String type)
        if firstDigit {
            setDisplay(s: "0")
            firstDigit = false
            userIsInTheMiddleOfTyping = false
        } else if display.text == "True" || display.text == "False" {
            setDisplay(s: digit)
            userIsInTheMiddleOfTyping = false
        }
        if userIsInTheMiddleOfTyping {
            let textCurrentlyInDisplay = display.text!
            setDisplay(s: textCurrentlyInDisplay, t: digit)
        } else {
            setDisplay(s: digit)
        }
    }
    
    private var displayValue: Double? {
        get {
            if String(describing: display.text!.characters.first) == " " {
                return nil
            } else if let ret = Double(display.text!) {
                return ret
            } else {
                return nil
            }
//            return Double(display.text!)! // the outer exclamation point tells compiler the Double is a Double, and not a nil from an Optional (and it would break if display.text == "hello", e.g.).
        }
        set {
            let s = String(describing: newValue)
            let t = s.components(separatedBy: ".")
            if boolOperationTouched {
                boolOperationTouched = false
                if isZero(z: String(describing: newValue)) {
                    display.text = "False"
                } else {
                    display.text = "True"
                }
            } else if t[1] == "0" { // correctly display a double that's semantically an int (as an int)
                display.text = t[0]
            } else {
                display.text = s
            }
        }
    }
    
    private func setDisplayWrapper(s: String) {
        if s.characters.count > 1 {
            // see http://stackoverflow.com/questions/39677330/how-does-string-substring-work-in-swift-3
            
            let aStart = s.startIndex
            let aEnd = s.index(s.startIndex, offsetBy: 1)
            let aRange = aStart..<aEnd
            let a = s.substring(with: aRange)
            
            let bStart = s.index(s.startIndex, offsetBy: 1)
            let bEnd = s.endIndex
            let bRange = bStart..<bEnd
            let b = s.substring(with: bRange)
            
            setDisplay(s: a, t: b)
        } else {
            setDisplay(s: s)
        }
    }
    
    private var brain = calculatorBrain()
    
    @IBAction private func performOperation(_ sender: UIButton) {
        let operation = sender.currentTitle
        if operation! == "p?" {
            boolOperationTouched = true
        }
        if userIsInTheMiddleOfTyping {
            if operation == "del" {
                if display.text != nil {
                    var newText = String(String(display.text!).characters.dropLast(1))
                    if String(newText).characters.count == 0 {
                        newText = " " // to avoid disappearing display
                        firstDigit = true
                        userIsInTheMiddleOfTyping = false
                    }
                    display.text = stringToDoubleFormattedString(d: newText)
                }
            } else {
                if displayValue != nil {
                    brain.setOperand(operand: displayValue!)
                }
//                displayValue = brain.result
                display.text = stringToDoubleFormattedString(d: String(brain.result))
            }
        }
        if let mathematicalSymbol = operation {
            if operation != "del" {
                brain.performOperation(symbol: mathematicalSymbol)
                display.text = stringToDoubleFormattedString(d: String(brain.result))
                userIsInTheMiddleOfTyping = false
            }
        }
        if brain.isPartialResult {
            descriptionOfOperations.text = "history: " + brain.description + "..."
        } else if operation != "del" {
            descriptionOfOperations.text = "history: " + brain.description + " = "
        }
        if operation! == "c" {
            setDisplayWrapper(s: "0")
            firstDigit = true
            userIsInTheMiddleOfTyping = false
            descriptionOfOperations.text = "history: "
        }
    }
}

