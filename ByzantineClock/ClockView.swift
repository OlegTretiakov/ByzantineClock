//
//  ClockView.swift
//  ByzantineClock
//
//  Created by Олег Третьяков on 05.02.16.
//  Copyright © 2016 Олег Третьяков. All rights reserved.
//

import UIKit

class ClockView: UIView {

    var timeInMinutes = 0
    var noData = true
    
    override func drawRect(rect: CGRect) {
        let clockImage = UIImage(named: "clock737.jpg")
        let imageRect = self.bounds
        clockImage?.drawInRect(imageRect)
        
        if !noData {
            var startPoint = CGPoint()
            startPoint.x = imageRect.origin.x + imageRect.width / 2
            startPoint.y = imageRect.origin.y + imageRect.height / 2 + 3 //Погрешность в центровке часов относительно рисунка
            var context = UIGraphicsGetCurrentContext()
            CGContextSetLineWidth(context, 3.0)
            CGContextSetFillColorWithColor(context, UIColor.redColor().CGColor)
            let rectangle = CGRectMake(startPoint.x - 6, startPoint.y - 6, 12, 12)
            CGContextAddEllipseInRect(context, rectangle)
            CGContextFillPath(context)
            
            let lineInPixels = (imageRect.height / 2) * 0.7
            let angle = (Double(timeInMinutes) / 1440) * M_PI * 2
            var endPoint = CGPoint()
            endPoint.x = startPoint.x + CGFloat(cos(angle)) * lineInPixels
            endPoint.y = startPoint.y + CGFloat(sin(angle)) * lineInPixels
            context = UIGraphicsGetCurrentContext()
            CGContextSetLineWidth(context, 3.0)
            CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor)
            CGContextMoveToPoint(context, startPoint.x, startPoint.y)
            CGContextAddLineToPoint(context, endPoint.x, endPoint.y)
            CGContextStrokePath(context)
        }
    }
    
}
