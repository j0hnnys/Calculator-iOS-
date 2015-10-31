//
//  GraphViewController.swift
//  Calc
//
//  Created by Johnny Nguyen on 10/21/15.
//  Copyright © 2015 Johnny Nguyen. All rights reserved.
//

import Foundation
import UIKit

class GraphViewController: UIViewController, GraphViewDataSource {
    
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
        }
    }
    
    func y(x: CGFloat) -> CGFloat? {
        brain.variableValues["M"] = Double(x)
        if let y = brain.evaluate() {
            return CGFloat(y)
        }
        return nil
    }
    
    private var brain = CalculatorBrain()
    
    typealias PropertyList = AnyObject
    var program: PropertyList {
        get {
            return brain.program
        }
        set {
            brain.program = newValue
        }
    }
    @IBAction func drawLineFromPan(sender: UIPanGestureRecognizer) {
        print("drawing line..")
        
        let iPoint = sender.locationInView(graphView)
        
        let path = UIBezierPath()
        path.moveToPoint(iPoint)
        path.addLineToPoint(iPoint)
        
        let fPoint = sender.locationInView(graphView)
        path.moveToPoint(fPoint)
        
        path.stroke()
        
        graphView.drawLine(path)
    }
}
