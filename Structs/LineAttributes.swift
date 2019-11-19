//
//  LineAttributes.swift
//  GridSnap
//
//  Created by Milos Jagetic on 02/09/2019.
//  Copyright © 2019 Milos Jagetic. All rights reserved.
//

import Foundation
import UIKit

public class LineAttributes
{
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Public -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    public var color: UIColor
    public var divisor: Int
    public var dashes: [CGFloat]
    public var lineWidth: CGFloat
    public var roundedCap: Bool
    
    public init(color: UIColor, divisor: Int, dashes: [CGFloat], lineWidth: CGFloat, roundedCap: Bool)
    {
        self.color = color
        self.divisor = divisor
        self.dashes = dashes
        self.lineWidth = lineWidth
        self.roundedCap = roundedCap
    }
    
    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Internal -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    internal var lineSegments: [Range<CGFloat>] = []
    
    internal func calculateLineSegments(maxOffset: CGFloat)    {
        guard dashes.count > 1 else
        {
            lineSegments = []
            return
        }
        
        var currentOffset: CGFloat = 0
        
        var isFull: Bool = true
        
        while currentOffset < maxOffset
        {
            for dash in dashes
            {
                if isFull
                {
                    lineSegments.append(currentOffset..<(currentOffset + dash))
                }
                currentOffset += dash
                isFull.toggle()
            }
        }
    }

}
