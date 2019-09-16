//
//  LayoutProperties.swift
//  MJGridView
//
//  Created by Milos Jagetic on 16/09/2019.
//

import Foundation

///This struct contains properties which are constant for each layout of the UI. For performance reasons they are calculated once per layout and stored here just to keep things tidy
internal struct LayoutProperties
{
    var remainderOnEachEnd: CGPoint = .zero
    var lastReportedTileFrame: CGRect = .zero
    var verticalLineCount: UInt = 0
    var horizontalLineCount: UInt = 0
    
    private(set) var lastReportedBounds: CGRect = .zero
    
    mutating func setLastReportedBounds(lastReportedBounds: CGRect, tileSideLength: CGFloat)
    {
        self.lastReportedBounds = lastReportedBounds
        
        remainderOnEachEnd.x = lastReportedBounds.width.truncatingRemainder(dividingBy: tileSideLength)
        remainderOnEachEnd.y = lastReportedBounds.height.truncatingRemainder(dividingBy: tileSideLength)
    }
}
