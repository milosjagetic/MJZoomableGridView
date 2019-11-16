//
//  GridProperties.swift
//  MJGridView
//
//  Created by Milos Jagetic on 15/11/2019.
//

import Foundation

public struct GridProperties
{
    var horizontalLineAttributes: [LineAttributes] = []
    var horizontalAxisAttributes: LineAttributes?
    
    var verticalLineAttributes: [LineAttributes] = []
    var verticalAxisAttributes: [LineAttributes] = []
    
    var lineWidth: CGFloat = 1 / UIScreen.main.scale
    var lineColor: UIColor = .black
    
    var pixelsPerLine: UInt = 112
    
    var scale: CGFloat = 1
    
    var originPlacement: OriginPlacement = .center
}
