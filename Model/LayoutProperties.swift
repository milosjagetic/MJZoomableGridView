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
    private(set) var lastReportedBounds: CGRect = .zero
    private(set) var boundsArea: CGFloat = 0
    
    private(set) var verticalLineCounts: [CGFloat : UInt] = [:]
    private(set) var horizontalLineCounts: [CGFloat : UInt] = [:]
    private(set) var remaindersOnEachEndArray: [CGFloat : UIEdgeInsets] = [:]

    mutating func calculateLayoutProperties(lastReportedBounds: CGRect, tileSideLength: CGFloat, pointsPerLine: UInt, originPlacement: OriginPlacement, levelsOfDetail: UInt, zoomInLevels: UInt)
    {
        self.lastReportedBounds = lastReportedBounds
        boundsArea = lastReportedBounds.width * lastReportedBounds.height

        verticalLineCounts = Dictionary<CGFloat, UInt>()
        horizontalLineCounts = Dictionary<CGFloat, UInt>()
        remaindersOnEachEndArray = Dictionary<CGFloat, UIEdgeInsets>()
        
        var remaindersOnEachEnd: UIEdgeInsets = .zero
        var verticalLineCount: UInt = 0
        var horizontalLineCount: UInt = 0
        
        let zoomOutLevels: UInt = levelsOfDetail - zoomInLevels - 1
        
        for currentLevel in 0..<levelsOfDetail
        {
            let relativeLevel: Double = Double(currentLevel) - Double(zoomOutLevels)
            let zoomScale: CGFloat = CGFloat(pow(2, relativeLevel))
            
            let pointsPerLine: CGFloat = CGFloat(pointsPerLine) / zoomScale
            let targetWidth: CGFloat = lastReportedBounds.width
            let targetHeight: CGFloat = lastReportedBounds.height
            
            let widthPplRemainder: CGFloat = targetWidth.truncatingRemainder(dividingBy: pointsPerLine)
            //do horizontal axis
            switch originPlacement
            {
            case .topLeft, .centerLeft, .bottomLeft:
                remaindersOnEachEnd.right = widthPplRemainder == 0 ? pointsPerLine : widthPplRemainder
            case .topCenter, .center, .bottomCenter:
                remaindersOnEachEnd.left = (targetWidth / 2).truncatingRemainder(dividingBy: pointsPerLine)
                remaindersOnEachEnd.right = remaindersOnEachEnd.left
            case .topRight, .centerRight, .bottomRight:
                remaindersOnEachEnd.left = widthPplRemainder == 0 ? pointsPerLine : widthPplRemainder
            }
            
            switch originPlacement
            {
            case .topCenter, .center, .bottomCenter:
                if remaindersOnEachEnd.left == 0
                {
                    verticalLineCount = UInt(targetWidth / pointsPerLine)
                }
                else
                {
                    verticalLineCount = UInt((targetWidth - remaindersOnEachEnd.left - remaindersOnEachEnd.right) / pointsPerLine) + 1
                }
            default:
                verticalLineCount = UInt(ceil(targetWidth / pointsPerLine))
            }
            
            verticalLineCounts[zoomScale] = verticalLineCount
            
            
            let heightPplRemainder: CGFloat = targetHeight.truncatingRemainder(dividingBy: pointsPerLine)
            
            // vertical axis
            switch originPlacement
            {
            case .topLeft, .topCenter, .topRight:
                remaindersOnEachEnd.bottom = heightPplRemainder == 0 ? pointsPerLine : heightPplRemainder
            case .centerLeft, .center, .centerRight:
                remaindersOnEachEnd.top = (targetHeight / 2).truncatingRemainder(dividingBy: pointsPerLine)
                remaindersOnEachEnd.bottom = remaindersOnEachEnd.top
            case .bottomRight, .bottomCenter, .bottomLeft:
                remaindersOnEachEnd.top = heightPplRemainder == 0 ? pointsPerLine : heightPplRemainder
            }
            
            switch originPlacement
            {
            case .centerLeft, .center, .centerRight:
                if remaindersOnEachEnd.top == 0
                {
                    horizontalLineCount = UInt(targetHeight / pointsPerLine)
                }
                else
                {
                    horizontalLineCount = UInt((targetHeight - remaindersOnEachEnd.top - remaindersOnEachEnd.bottom) / pointsPerLine) + 1
                }
            default:
                horizontalLineCount = UInt(ceil(targetHeight / pointsPerLine))
            }

            horizontalLineCounts[zoomScale] = horizontalLineCount
            
            remaindersOnEachEndArray[zoomScale] = remaindersOnEachEnd
        }
    }
    
    func verticalLineCount(scale: CGFloat) -> UInt
    {
        return verticalLineCounts[scale] ?? 0
    }
    
    func horizontalLineCount(scale: CGFloat) -> UInt
    {
        return horizontalLineCounts[scale] ?? 0
    }
    
    func remaindersOnEachEnd(scale: CGFloat) -> UIEdgeInsets
    {
        return remaindersOnEachEndArray[scale] ?? .zero
    }
}
