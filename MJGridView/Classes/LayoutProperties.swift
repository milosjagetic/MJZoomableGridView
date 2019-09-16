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
    private(set) var verticalLineCount: UInt = 0
    private(set) var horizontalLineCount: UInt = 0
    private(set) var lastReportedBounds: CGRect = .zero
    private(set) var remainderOnEachEnd: CGPoint = .zero

    mutating func setLastReportedBounds(lastReportedBounds: CGRect, tileSideLength: CGFloat, pointsPerLine: UInt)
    {
        self.lastReportedBounds = lastReportedBounds
        
        remainderOnEachEnd.x = lastReportedBounds.width.truncatingRemainder(dividingBy: tileSideLength)
        remainderOnEachEnd.y = lastReportedBounds.height.truncatingRemainder(dividingBy: tileSideLength)
        
        horizontalLineCount = UInt(floor(lastReportedBounds.width / CGFloat(pointsPerLine)))
        verticalLineCount = UInt(floor(lastReportedBounds.height / CGFloat(pointsPerLine)))
    }
}
