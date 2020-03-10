//
//  GridProperties.swift
//  MJGridView
//
//  Created by Milos Jagetic on 15/11/2019.
//

import Foundation

private struct __
{
    static let defaultAttributes: [NSAttributedString.Key : Any] = [.font : UIFont.systemFont(ofSize: 20),
                                                                    .foregroundColor: UIColor.gray]
}

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
    
    /// Scale of the whole grid. e.g. if `1`, line on the right, next to origin will have value of `1`, the one on the left `-1`. if  `10` then `10` and `-10`.
    public var scale: CGFloat = 1
    
    /// Origins position within the view
    public var originPlacement: OriginPlacement = .center
    
    /// Vertical axis label instes. Relative to vertical axis and horizontal lines
    public var verticalAxisLabelInsets: UIEdgeInsets = .zero
    
    /// Horizontal axis label insets. Relative to horiontal axis and vertical lines
    public var horizontalAxisLabelInsets: UIEdgeInsets = .zero
    
    /// Vertical axis label attributes
    public var verticalAxisLabelAttributes: [NSAttributedString.Key : Any] = __.defaultAttributes
    
    /// Horizontal axis label attributes
    public var horizontalAxisLabelAttributes: [NSAttributedString.Key : Any] = __.defaultAttributes
    
    public init() {}
}
