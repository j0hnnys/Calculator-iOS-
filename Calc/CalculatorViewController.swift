//
//  ViewController.swift
//  Calculator
//
//  Created by Johnny Nguyen on 8/27/15.
//  Copyright (c) 2015 Johnny Nguyen. All rights reserved.
//

import UIKit

extension String {
    
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: startIndex.advancedBy(r.startIndex), end: startIndex.advancedBy(r.endIndex)))
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var display: UILabel!
    var userIsInTheMiddleOfTypingANumber = false
    var brain = CalculatorBrain()
    var currentChar: String = ""
    var operandStack = [Double]()
    
    var displayValue: Double! {
        get {
            if display.text == nil {
                return 0
            }
            return NSNumberFormatter().numberFromString(display.text!)!.doubleValue
        }
        set {
            if newValue == 0 {
                display.text = nil
            } else {
                print("newValue: \(newValue)")
                display.text = newValue!.description
            }
            userIsInTheMiddleOfTypingANumber = false
        }
    }
    
    @IBAction func alphaButton(sender: UIButton) {
        brain.setAlpha(!brain.isAlphaPressed())
        let isPressed = brain.isAlphaPressed()
        if (isPressed) {
            sender.setTitle("ALPHA", forState: UIControlState.Normal)
        } else {
            sender.setTitle("alpha", forState: UIControlState.Normal)
        }
    }
    
    // appends variable if alpha button is on
    private func alphaAction(sender: UIButton) -> String {
        
        let str = sender.currentTitle!
        let c = String(str.characters.last!)
        
        display.text = c
        currentChar = c
        
        brain.addToHistory(c)
        
        return c
    }
    
    private var clearPressed:Bool = false
    @IBAction func clearButton(sender: UIButton) {
        if brain.isAlphaPressed() {
            alphaAction(sender)
            return
        }
        
        brain.addToHistory(sender.currentTitle!)
        
        if clearPressed == false {
            if display.text == nil  {
                clearPressed = true
                return
            }
            displayValue = 0
        } else {
            brain.clearHistory()
            brain.clearOpStack()
            
            if operandStack.count > 0 {
                operandStack.removeAll()
            }
            
            displayValue = 0
            print("operandStack cleared: \(operandStack)")
            print("history stack cleared: \(brain.getHistory())")
            
            // Notifies users of full clear
            let alert = UIAlertController(title: "Cleared!", message: "Operand and history stack cleared.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            // -----------------
            
            clearPressed = false
        }
    }
    
    // select variable if Alpha button is pressed,
    // append digit otherwise
    @IBAction func appendDigit(sender: UIButton) {
        if brain.isAlphaPressed() {
            alphaAction(sender)
            return
        }
        
        brain.addToHistory(sender.currentTitle!)
        let str = sender.currentTitle!
        let digit = String(str.characters.first!)
        
        print("Digit appended: \(digit)")
        if userIsInTheMiddleOfTypingANumber {
            display.text! = display.text! + digit
        } else {
            display.text = digit
            userIsInTheMiddleOfTypingANumber = true
        }
    }
    
    @IBAction func percentAction(sender: UIButton) {
        if brain.isAlphaPressed() {
            alphaAction(sender)
            return
        }
        displayValue = (operandStack.removeLast() / 100)
    }
    
    @IBAction func operate(sender: UIButton) {
        if brain.isAlphaPressed() {
            alphaAction(sender)
            return
        }
        
        brain.addToHistory(sender.currentTitle!)
        
        if let operation = sender.currentTitle {
            
            let str = operation
            
            let index = str.startIndex.advancedBy(3)
            let subStr = str.substringToIndex(index)
            
            let c: String
            if subStr == "cos" {
                c = subStr
            } else {
                c = String(str.characters.first!)
            }
            
            if let result = brain.performOperation(c) {
                displayValue = result
            } else {
                displayValue = 0;
            }
        }
        
        display.text = brain.getLastExpression()
    }

    @IBOutlet weak var enterButton: UIButton!
    @IBAction func enter(sender: UIButton) {
        
        if brain.isAlphaPressed() {
            alphaAction(sender)
            return
        }
        
        brain.addToHistory(enterButton.currentTitle!)
        userIsInTheMiddleOfTypingANumber = false
        
        // checks if variable is on display (ALPHA)
        let str = display.text!
        let num = NSNumberFormatter().numberFromString(str)
        
        // for alpha
        if num == nil {
            brain.pushOperand(currentChar)
        } // for operations
        else if let result = brain.pushOperand(displayValue) {
            displayValue! = result
            
            operandStack.append(displayValue)
            print("operandStack = \(operandStack)")
        } else {
            // This is lame
            displayValue = 0
        }
    }
    
    @IBAction func setLastVariableEntered(sender: UIButton) {
        brain.setLastVariable()
        print(brain.getLastExpression())
        display.text = brain.getLastExpression()
    }
    
    @IBAction func fraction(sender: UIButton) {
        if brain.isAlphaPressed() {
            alphaAction(sender)
            return
        }
        
        brain.addToHistory(sender.currentTitle!)
        
        if userIsInTheMiddleOfTypingANumber {
            let frac = brain.getFractionValue(sender)
            print("displayValue: \(displayValue)")
            displayValue = displayValue + frac
            print(brain.getFractionValue(sender))
        } else {
            displayValue = brain.getFractionValue(sender)
            print(brain.getFractionValue(sender))
        }
    }
    
    @IBAction func showHistory(sender: UIButton) {
        if brain.isAlphaPressed() {
            alphaAction(sender)
            return
        }
        brain.printHistory()
    }
    
    @IBAction func memoryFunction(sender: UIButton) {
        if brain.isAlphaPressed() {
            alphaAction(sender)
            return
        }
        
        brain.addToHistory(sender.currentTitle!)
        let symbol: String = sender.currentTitle!
        
        switch symbol {
        case "MC / A":
            brain.memory = 0
            print("memory = \(brain.memory)")
        case "MR / B":
            displayValue = brain.memory
            print("memory = \(brain.memory)")
        case "MS / C":
            brain.memory = displayValue
            print("memory = \(brain.memory)")
        case "M+ / D":
            brain.memory += displayValue
            print("memory = \(brain.memory)")
        default: break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
