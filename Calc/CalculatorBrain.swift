
import UIKit
import Darwin

//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Johnny Nguyen on 9/3/15.
//  Copyright (c) 2015 Johnny Nguyen. All rights reserved.
//

import Foundation

class CalculatorBrain {
    
    // to store expressions
    var expressionStack = [String]()
    private var history = [String]()
    private var alpha: Bool = false
    var memory: Double = 0;
    
    var variableValues = [String:Double]()
    
    private var opStack = [Op]()
    private var knownOps = [String:Op]()
    
    // Any function using Op must be private
    private enum Op: CustomStringConvertible {
        
        // For numbers
        case Operand(Double)
        // For operations with one parameter (eg. square root)
        case UnaryOperation(String, Double -> Double)
        // For operations with two parameters
        case BinaryOperation(String, (Double, Double) -> Double)
        // For variables
        case Variable(String)
        
        var description: String {
            get {
                switch self {
                case .Operand(let operand):
                    return "\(operand)"
                case .UnaryOperation(let symbol,_):
                    return symbol
                case .BinaryOperation(let symbol,_):
                    return symbol
                case .Variable(let symbol):
                    return symbol
                }
            }
        }
    }
    
    init() {
        func learnOp(op: Op) {
            knownOps[op.description] = op
        }
        
        learnOp(Op.BinaryOperation("✖️", *))
        knownOps["➗"] = Op.BinaryOperation("➗", {$1 / $0})
        knownOps["➕"] = Op.BinaryOperation("➕", +)
        knownOps["➖"] = Op.BinaryOperation("➖", {$1 - $0})
        knownOps["✔️"] = Op.UnaryOperation("✔️", sqrt)
        knownOps["cos"] = Op.UnaryOperation("cos", cos)
    }
    
    typealias propertyList = AnyObject
    
    var program: propertyList { // guaranteed to be a PropertyList
        get {
            /**
            var returnValue = Array<String>()
            for op in opStack {
            returnValue.append(op.description)
            }
            return returnValue
            **/
            
            return opStack.map( {$0.description})
        }
        set {
            if let opSymbols = newValue as? Array<String> {
                var newOpStack = [Op]()
                for opSymbol in opSymbols {
                    if let op = knownOps[opSymbol] {
                        newOpStack.append(op)
                    } else if let operand = NSNumberFormatter().numberFromString(opSymbol)?.doubleValue {
                        newOpStack.append(.Operand(operand))
                    }
                }
                opStack = newOpStack
            }
        }
    }
    
    private func evaluate (ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            
            switch op {
                
            case .Operand(let operand): // .Operand knows that op.Operand is implied
                expressionStack.append(op.description)
                
                return (operand, remainingOps)
                
            case .UnaryOperation(_, let operation):
                expressionStack.append(op.description)
                
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result {
                    return (operation(operand), operandEvaluation.remainingOps)
                }
                
            case .BinaryOperation(_, let operation):
                expressionStack.append(op.description)
                
                let op1Evaluation = evaluate(remainingOps)
                
                if let operand1 = op1Evaluation.result {
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.result {
                        return (operation(operand1, operand2), op2Evaluation.remainingOps)
                    }
                }
                
            case .Variable(let variable):
                expressionStack.append(variable)
                return (variableValues[variable], remainingOps)
            }
        }
        return (nil, ops)
    }
    
    func evaluate() -> Double? {  // Optional
        // Perfect opportunity to use recursion for this equation (imagine stack with numbers and operators)
        
        let (result, _) = evaluate(opStack)
        
        // checks operationsStack
        if let recentOp = opStack.popLast() {
            opStack.append(recentOp)
            
            if let _ = NSNumberFormatter().numberFromString(recentOp.description)?.doubleValue {
                // do nothing since no operation is done (only number in stack)
            } else {
                expressionStack.append(recentOp.description)
                let expression = checkForExpression()
                expressionStack.append("\(expression) = ")
            }
        }
        
        // to round any long results to 2 digits after decimal
        let multiplier = pow(10.0, 2.0)
        let rounded = round(result! * multiplier) / multiplier
        
        // create a NS formatter class to convert rounded result to string
        let nf = NSNumberFormatter()
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 2
        nf.numberStyle = .DecimalStyle
        
        let resultToString = nf.stringFromNumber(rounded)
        expressionStack[expressionStack.count-1].appendContentsOf(resultToString!)

        print("expressionStack \(expressionStack)")
        
        return rounded
    }
    
    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.Variable(symbol))
        return variableValues[symbol]
    }
    
    func performOperation(symbol: String) -> Double? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        return evaluate()
    }
    
    func setVariableValue(symbol: String, value: Double) -> Double {
        variableValues[symbol] = value
        return variableValues[symbol]!
    }
    
    func setLastVariable() {
        let stringValue = opStack.popLast()?.description
        let value = NSNumberFormatter().numberFromString(stringValue!)!.doubleValue
        let alphaValue = opStack.removeLast().description
        
        expressionStack.append("\(alphaValue) = \(value)")
        setVariableValue(alphaValue, value: value)
    }

    // given a fraction button as an argument, returns
    // the appropriate fraction value for that button
    func getFractionValue(sender: UIButton) -> Double {
        let str = sender.currentTitle!
        let s = str.startIndex.advancedBy(1)
        let substr = str.substringToIndex(s)
        let value1 = NSNumberFormatter().numberFromString(substr)!
        
        let startIndex = str.startIndex.advancedBy(2)
        let endIndex = str.startIndex.advancedBy(3)
        let substr2 = str.substringWithRange(startIndex..<endIndex)
        
        let value2 = NSNumberFormatter().numberFromString(substr2)!
        
        let fractionValue = (Double(value1) / Double(value2))
        return fractionValue
    }
    
    // get method for alpha
    func isAlphaPressed() -> Bool {
        return alpha
    }
    
    // set method for alpha
    func setAlpha(isTrue: Bool) {
        alpha = isTrue
    }
    
    // adds actions to history
    func addToHistory(item: String) {
        history.append(item)
    }
    
    // returns the history of actions
    func getHistory() -> [String] {
        return history
    }
    
    // prints the history of actions
    func printHistory() {
        print(history)
    }
    
    // prints the opStack
    func printOpStack() {
        print(opStack)
    }
    
    // clears the opStack
    func clearOpStack() {
        if opStack.count > 0 {
            opStack.removeAll()
        }
    }
    
    // clears the history of actions
    func clearHistory() {
        if history.count > 0 {
            history.removeAll()
        }
    }
    
    // checks for expressions in expressionStack
    // returns last expression
    func checkForExpression() -> String {
        
        var expressionString: String = ""

        let lastOp = expressionStack.popLast()
        
        if lastOp == "cos" || lastOp == "✔️" {
            expressionString.appendContentsOf(lastOp!)
            expressionString.appendContentsOf("(")
            expressionString.appendContentsOf(expressionStack.popLast()!)
            expressionString.appendContentsOf(")")
            
            expressionStack.popLast()
            expressionStack.popLast()
            
            return expressionString
        } else if lastOp == "➖" || lastOp == "➗" {
            expressionString.appendContentsOf(expressionStack.popLast()!)
            expressionString.appendContentsOf(lastOp!)
            expressionString.appendContentsOf(expressionStack.popLast()!)
            
            expressionStack.popLast()
            expressionStack.popLast()
            expressionStack.popLast()
            
            return expressionString
        } else {
            let secondNumber = expressionStack.popLast()!

            expressionString.appendContentsOf(expressionStack.popLast()!)
            expressionString.appendContentsOf(lastOp!)
            expressionString.appendContentsOf(secondNumber)
            
            expressionStack.popLast()
            expressionStack.popLast()
            expressionStack.popLast()
            
            return expressionString
        }
    }
    
    func getLastExpression() -> String {
        return expressionStack[expressionStack.count-1]
    }
    
}