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
    static let defaultLabelFormat: String = "%.1f"
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
    
    /// Scale of the whole grid. e.g. if `1`, line on the right, next to origin will have value of `1`, the one on the left `-1`. if  `10` then `10` and `-10`. For positive values negative part of the scale is on the left side of origin. If negative value given the scale is reversed.
    public var horizontalScale: CGFloat = 1
    /// Scale of the whole grid. e.g. if `1`, line on the bottom, next to origin will have value of `1`, the one on the top `-1`. if  `10` then `10` and `-10`. For positive values negative part of the scale is above the origin. If negative value given the scale is reversed.
    public var verticalScale: CGFloat = 1
    
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
    
    /// Horizontal axis label format
    public var horizontalAxisLabelFormat: String = __.defaultLabelFormat
    
    /// Vertical axis label format
    public var verticalAxisLabelFormat: String = __.defaultLabelFormat
    
    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Copy -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    func copy() -> GridProperties
    {
        return .init(horizontalLineAttributes: horizontalLineAttributes,
                     horizontalAxisAttributes: horizontalAxisAttributes,
                     verticalLineAttributes: verticalLineAttributes,
                     verticalAxisAttributes: verticalAxisAttributes,
                     lineWidth: lineWidth,
                     lineColor: lineColor,
                     pixelsPerLine: pixelsPerLine,
                     horizontalScale: horizontalScale,
                     verticalScale: verticalScale,
                     originPlacement: originPlacement,
                     verticalAxisLabelInsets: verticalAxisLabelInsets,
                     horizontalAxisLabelInsets: horizontalAxisLabelInsets,
                     verticalAxisLabelAttributes: verticalAxisLabelAttributes,
                     horizontalAxisLabelAttributes: horizontalAxisLabelAttributes,
                     horizontalAxisLabelFormat: horizontalAxisLabelFormat,
                     verticalAxisLabelFormat: verticalAxisLabelFormat)
    }
}
