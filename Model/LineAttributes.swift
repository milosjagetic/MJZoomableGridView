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
    public let color: UIColor
    public let divisor: Int
    public let dashes: [CGFloat]
    public let lineWidth: CGFloat
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
