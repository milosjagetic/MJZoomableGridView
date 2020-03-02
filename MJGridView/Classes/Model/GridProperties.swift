//
//  GridProperties.swift
//  MJGridView
//
//  Created by Milos Jagetic on 15/11/2019.
//

import Foundation

/// A struct for configuring the grid.
public struct GridProperties
{
    /// If multiple attributes' `divisor` divides the line value evenly only the first one found is used
    public var horizontalLineAttributes: [LineAttributes] = []
    /// Takes precendance on line 0 over all other attributes
    public var horizontalAxisAttributes: LineAttributes?
    
    /// If multiple attributes' `divisor` divides the line value evenly only the first one found is used
    public var verticalLineAttributes: [LineAttributes] = []
    /// Takes precendance on line 0 over all other attributes
    public var verticalAxisAttributes: LineAttributes?
    
    /// Default line width if no line attributes are applicable
    public var lineWidth: CGFloat = 1 / UIScreen.main.scale
    
    /// Default line color if no line attributes are applicable
    public var lineColor: UIColor = .black
    
    /// Spacing between the lines
    public var pixelsPerLine: UInt = 112
    
    /// Scale of the whole grid. e.g. if `1` line on the right, next to origin will have value of `1`, the one on the left `-1`. if  `10` then `10` and `-10`. Currently only influences where each of the line attributes will be applied
    public var scale: CGFloat = 1
    
    /// Origins position within the view
    public var originPlacement: OriginPlacement = .center
    
    public init() {}
}
