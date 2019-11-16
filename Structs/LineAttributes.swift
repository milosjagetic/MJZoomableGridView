//
//  LineAttributes.swift
//  GridSnap
//
//  Created by Milos Jagetic on 02/09/2019.
//  Copyright © 2019 Milos Jagetic. All rights reserved.
//

import Foundation
import UIKit

public struct LineAttributes
{
    public var color: UIColor
    public var divisor: Int
    public var dashes: [CGFloat]
    public var lineWidth: CGFloat
    
    public init(color: UIColor, divisor: Int, dashes: [CGFloat], lineWidth: CGFloat)
    {
        self.color = color
        self.divisor = divisor
        self.dashes = dashes
        self.lineWidth = lineWidth
    }
}
