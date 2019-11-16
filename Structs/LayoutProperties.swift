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
    private(set) var remaindersOnEachEnd: UIEdgeInsets = .zero
    
    mutating func calculateLayoutProperties(lastReportedBounds: CGRect, tileSideLength: CGFloat, pointsPerLine: UInt, originPlacement: OriginPlacement)
    {
        self.lastReportedBounds = lastReportedBounds
        
        let pointsPerLine: CGFloat = CGFloat(pointsPerLine)
        
        remaindersOnEachEnd = .zero
        
        let widthPplRemainder: CGFloat = lastReportedBounds.width.truncatingRemainder(dividingBy: pointsPerLine)
        //do horizontal axis
        switch originPlacement
        {
        case .topLeft, .centerLeft, .bottomLeft:
            remaindersOnEachEnd.right = widthPplRemainder == 0 ? pointsPerLine : widthPplRemainder
        case .topCenter, .center, .bottomCenter:
            remaindersOnEachEnd.left = (lastReportedBounds.width / 2).truncatingRemainder(dividingBy: pointsPerLine)
            remaindersOnEachEnd.right = remaindersOnEachEnd.left
        case .topRight, .centerRight, .bottomRight:
            remaindersOnEachEnd.left = widthPplRemainder == 0 ? pointsPerLine : widthPplRemainder
        }
        
        switch originPlacement
        {
        case .topCenter, .center, .bottomCenter:
            if remaindersOnEachEnd.left == 0
            {
                verticalLineCount = UInt(lastReportedBounds.width / pointsPerLine)
            }
            else
            {
                verticalLineCount = UInt((lastReportedBounds.width - remaindersOnEachEnd.left - remaindersOnEachEnd.right) / pointsPerLine) + 1
            }
        default:
            verticalLineCount = UInt(ceil(lastReportedBounds.width / pointsPerLine))
        }
        
        
        let heightPplRemainder: CGFloat = lastReportedBounds.height.truncatingRemainder(dividingBy: pointsPerLine)
        
        // vertical axis
        switch originPlacement
        {
        case .topLeft, .topCenter, .topRight:
            remaindersOnEachEnd.bottom = heightPplRemainder == 0 ? pointsPerLine : heightPplRemainder
        case .centerLeft, .center, .centerRight:
            remaindersOnEachEnd.top = (lastReportedBounds.height / 2).truncatingRemainder(dividingBy: pointsPerLine)
            remaindersOnEachEnd.bottom = remaindersOnEachEnd.top
        case .bottomRight, .bottomCenter, .bottomLeft:
            remaindersOnEachEnd.top = heightPplRemainder == 0 ? pointsPerLine : heightPplRemainder
        }
        
        switch originPlacement
        {
        case .centerLeft, .center, .centerRight:
            if remaindersOnEachEnd.top == 0
            {
                horizontalLineCount = UInt(lastReportedBounds.height / pointsPerLine)
            }
            else
            {
                horizontalLineCount = UInt((lastReportedBounds.height - remaindersOnEachEnd.top - remaindersOnEachEnd.bottom) / pointsPerLine) + 1
            }
        default:
            horizontalLineCount = UInt(ceil(lastReportedBounds.height / pointsPerLine))
        }
    }
}
