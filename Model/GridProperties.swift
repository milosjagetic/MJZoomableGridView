//
//  GridProperties.swift
//  MJGridView
//
//  Created by Milos Jagetic on 15/11/2019.
//

import Foundation

public struct GridProperties
{
    public var horizontalLineAttributes: [LineAttributes] = []
    public var horizontalAxisAttributes: LineAttributes?
    
    public var verticalLineAttributes: [LineAttributes] = []
    public var verticalAxisAttributes: LineAttributes?
    
    public var lineWidth: CGFloat = 1 / UIScreen.main.scale
    public var lineColor: UIColor = .black
    
    public var pixelsPerLine: UInt = 112
    
    public var scale: CGFloat = 1
    
    public var originPlacement: OriginPlacement = .center
    
    public init() {}
}
