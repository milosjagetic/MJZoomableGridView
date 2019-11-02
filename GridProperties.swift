//
//  GridProperties.swift
//  MJGridView
//
//  Created by Milos Jagetic on 02/11/2019.
//

import Foundation

public struct GridProperties
{
    public var horizontalLineAttributes: [LineAttributes] = [LineAttributes(color: .red, divisor: 3, dashes: [16, 16], lineWidth: 5)]
    public var horintalAxisAttributes: LineAttributes? = LineAttributes(color: .green, divisor: 0, dashes: [], lineWidth: 10)
    public var verticalLineAttributes: [LineAttributes] = [LineAttributes(color: .blue, divisor: 3, dashes: [], lineWidth: 1)]
    public var verticalAxisAttributes: LineAttributes? = LineAttributes(color: .cyan, divisor: 0, dashes: [], lineWidth: 10)
    
    public var lineColor: UIColor = .black

    
    public var originPlacement: OriginPlacement = .center
    public var pixelsPerLine: UInt = 112
    public var lineWidth: CGFloat = 1 / UIScreen.main.scale
    public var scale: CGFloat = 1
}
