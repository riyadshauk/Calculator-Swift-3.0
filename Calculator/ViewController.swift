//
//  ViewController.swift
//  Calculator
//
//  Created by Riyad Shauk on 1/9/17.
//  Copyright © 2017 Riyad Shauk. All rights reserved.
//  Code largely inspired from Stanford's CS 193p Swift Programming course; I programmed and commented this while going through the tutorials.
//  FYI: This is meant to be viewed in Xcode, as Xcode automatically line-wraps (in case you were wondering about the very long comments).
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
    
    private var delJustPressed = false
    
    private func setDisplay(s: String) {
        if s == "." {
            if !userIsInTheMiddleOfTyping {
                display.text = "0."
            } else if userAlreadyTypedADecimal() {
                // do nothing
            } else {
                display.text! += s
            }
        } else if !boolOperationTouched {
            if display.text == " " || display.text == "True" || display.text == "False" {
                display.text = ""
            }
            if userIsInTheMiddleOfTyping {
                display.text = stringToDoubleFormattedString(d: display.text! + s)
            } else {
                display.text = stringToDoubleFormattedString(d: s)
            }
        } else {
            boolOperationTouched = false
            if isZero(z: s) {
                display.text = "False"
            } else {
                display.text = "True"
            }
        }
    }

    @IBAction private func touchDigit(_ sender: UIButton) {
        delJustPressed = false
        if display.text == " " {
            setDisplay(s: "0")
        }
        let digit = sender.currentTitle!
        setDisplay(s: digit)
        userIsInTheMiddleOfTyping = true
    }
    
    private var displayValue: Double? {
        get {
            if String(describing: display.text!.characters.first) == " " {
                return 0.0
            } else if let ret = Double(display.text!) {
                return ret
            } else {
                return nil
            }
        }
    }
    
    private var brain = calculatorBrain()
    
    @IBAction private func performOperation(_ sender: UIButton) {
        let operation = sender.currentTitle
        if operation! != "del" && display.text == " " {
            delJustPressed = false
            setDisplay(s: "0")
            brain.setOperand(operand: 0.0)
        }
        if operation! == "p?" {
            boolOperationTouched = true
        }
        if userIsInTheMiddleOfTyping {
            if operation == "del" {
                delJustPressed = true
                if display.text != nil {
                    var newText = String(String(display.text!).characters.dropLast(1))
                    if String(newText).characters.count == 0 {
                        newText = " " // to avoid disappearing display
                        userIsInTheMiddleOfTyping = false
                    }
                    setDisplay(s: newText)
                }
            } else {
                if displayValue != nil {
                    brain.setOperand(operand: displayValue!)
                }
            }
        }
        if let mathematicalSymbol = operation {
            if operation != "del" {
                brain.performOperation(symbol: mathematicalSymbol)
                userIsInTheMiddleOfTyping = false
                setDisplay(s: String(describing: brain.result))
            }
        }
        if brain.isPartialResult {
            descriptionOfOperations.text = "history: " + brain.description + "..."
        } else if operation != "del" {
            descriptionOfOperations.text = "history: " + brain.description + " = "
        }
        if operation! == "c" {
            setDisplay(s: "0")
            userIsInTheMiddleOfTyping = false
            descriptionOfOperations.text = "history: "
        }
    }
}

