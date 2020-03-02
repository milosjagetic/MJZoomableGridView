//
//  LineAttributes.swift
//  GridSnap
//
//  Created by Milos Jagetic on 02/09/2019.
//  Copyright © 2019 Milos Jagetic. All rights reserved.
//

import Foundation
import UIKit

/// A struct defining attributes for each line divisble by `LineAttributes.divisor`
public class LineAttributes
{
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Public -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    /// Line's color
    public let color: UIColor
    /// Value which determines when these line attributes are applied. e.g. if `divisor` is `6` every line which divides evenly with `6` (6, 12, 24...) has these line attributes applied to it
    public let divisor: Int
    /// Line's dash pattern. See CGContext.setLineDash(offset:,dashes:) for more info.
    public let dashes: [CGFloat]
    /// Line's width
    public let lineWidth: CGFloat
    /// Wheather or not to put rounded caps on the of dashed lines. EXPERIMENTAL. Also resource intensive.
    public let roundedCap: Bool
    
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
    internal var dashOffsetWhenCentered: CGFloat = 0
    
    internal func calculateLineSegments(maxOffset: CGFloat)
    {
        lineSegments = []

        guard dashes.count > 1 else {return}
        
        let dashesLength: CGFloat = dashes.reduce(0, {$0 + $1})

        //so we get ahead a bit if the dash offset is used
        var currentOffset: CGFloat = -dashesLength
        
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
        
        
        dashOffsetWhenCentered = (maxOffset / 2).truncatingRemainder(dividingBy: dashesLength / 2)
    }
}
