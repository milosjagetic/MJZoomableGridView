//
//  LayoutProperties.swift
//  MJGridView
//
//  Created by Milos Jagetic on 16/09/2019.
//

import Foundation

///This struct contains properties which are constant for each layout of the UI. For performance reasons they are calculated once per layout and stored here just to keep things tidy
// Maybe change it to class. Maybe it will make multithreading harder
internal struct LayoutProperties
{
    private(set) var lastReportedBounds: CGRect = .zero
    private(set) var boundsArea: CGFloat = 0
    
    private(set) var lineSpacing: CGFloat = 0
    
    // TODO: Do something about this Atomic and double proprties voodoo
    @Atomic private(set) var verticalLineCounts: [CGFloat : UInt] = [:]
    @Atomic private(set) var horizontalLineCounts: [CGFloat : UInt] = [:]
    @Atomic private(set) var remaindersOnEachEndArray: [CGFloat : UIEdgeInsets] = [:]
    
    private(set) var __verticalLineCounts: [CGFloat : UInt] = [:]
    private(set) var __horizontalLineCounts: [CGFloat : UInt] = [:]
    private(set) var __remaindersOnEachEndArray: [CGFloat : UIEdgeInsets] = [:]
    
    init() {}
    
    init(lastReportedBounds: CGRect, boundsArea: CGFloat, verticalLineCounts: [CGFloat : UInt], horizontalLineCounts: [CGFloat : UInt], remaindersOnEachEndArray: [CGFloat : UIEdgeInsets], lineSpacing: CGFloat)
    {
        self.lastReportedBounds = lastReportedBounds
        self.boundsArea = boundsArea
        self.verticalLineCounts = verticalLineCounts
        self.horizontalLineCounts = horizontalLineCounts
        self.remaindersOnEachEndArray = remaindersOnEachEndArray
        self.lineSpacing = lineSpacing
    }

    mutating func calculateLayoutProperties(lastReportedBounds: CGRect, tileSideLength: CGFloat, pointsPerLine: UInt, originPlacement: OriginPlacement, levelsOfDetail: UInt, zoomInLevels: UInt)
    {
        self.lineSpacing = CGFloat(pointsPerLine)
        self.lastReportedBounds = lastReportedBounds
        boundsArea = lastReportedBounds.width * lastReportedBounds.height

        __verticalLineCounts = Dictionary<CGFloat, UInt>()
        __horizontalLineCounts = Dictionary<CGFloat, UInt>()
        __remaindersOnEachEndArray = Dictionary<CGFloat, UIEdgeInsets>()
                
        let zoomOutLevels: UInt = levelsOfDetail - zoomInLevels - 1
        
        for currentLevel in 0..<levelsOfDetail
        {
            var remaindersOnEachEnd: UIEdgeInsets = .zero
            var verticalLineCount: UInt = 0
            var horizontalLineCount: UInt = 0

            let relativeLevel: Double = Double(currentLevel) - Double(zoomOutLevels)
            let zoomScale: CGFloat = CGFloat(pow(2, relativeLevel))
            
            let pointsPerLine: CGFloat = CGFloat(pointsPerLine) / zoomScale
            let targetWidth: CGFloat = lastReportedBounds.width
            let targetHeight: CGFloat = lastReportedBounds.height
            
            let widthPplRemainder: CGFloat = targetWidth.truncatingRemainder(dividingBy: pointsPerLine)
            
            //do horizontal axis
            
            //remainders
            switch originPlacement
            {
            case .topLeft, .centerLeft, .bottomLeft:
                remaindersOnEachEnd.right = widthPplRemainder == 0 ? pointsPerLine : widthPplRemainder
            case .topCenter, .center, .bottomCenter:
                remaindersOnEachEnd.left = (targetWidth / 2).truncatingRemainder(dividingBy: pointsPerLine)
                remaindersOnEachEnd.right = remaindersOnEachEnd.left
            case .topRight, .centerRight, .bottomRight:
                remaindersOnEachEnd.left = widthPplRemainder == 0 ? pointsPerLine : widthPplRemainder
            case .custom(let x, _):
                remaindersOnEachEnd.left = x.truncatingRemainder(dividingBy: pointsPerLine)
                remaindersOnEachEnd.right = (targetWidth - x).truncatingRemainder(dividingBy: pointsPerLine)
            }
            
            //line count
            switch originPlacement
            {
            case .topCenter, .center, .bottomCenter, .custom(_, _):
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
            
            __verticalLineCounts[zoomScale] = verticalLineCount
            
            
            let heightPplRemainder: CGFloat = targetHeight.truncatingRemainder(dividingBy: pointsPerLine)
            
            //do vertical axis
            
            //remainders
            switch originPlacement
            {
            case .topLeft, .topCenter, .topRight:
                remaindersOnEachEnd.bottom = heightPplRemainder == 0 ? pointsPerLine : heightPplRemainder
            case .centerLeft, .center, .centerRight:
                remaindersOnEachEnd.top = (targetHeight / 2).truncatingRemainder(dividingBy: pointsPerLine)
                remaindersOnEachEnd.bottom = remaindersOnEachEnd.top
            case .bottomRight, .bottomCenter, .bottomLeft:
                remaindersOnEachEnd.top = heightPplRemainder == 0 ? pointsPerLine : heightPplRemainder
            case .custom(_, let y):
                remaindersOnEachEnd.top = y.truncatingRemainder(dividingBy: pointsPerLine)
                remaindersOnEachEnd.bottom = (targetHeight - y).truncatingRemainder(dividingBy: pointsPerLine)
            }
            
            
            //line count
            switch originPlacement
            {
            case .centerLeft, .center, .centerRight, .custom(_, _):
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

            __horizontalLineCounts[zoomScale] = horizontalLineCount
            
            __remaindersOnEachEndArray[zoomScale] = remaindersOnEachEnd
        }
        
        verticalLineCounts = __verticalLineCounts
        horizontalLineCounts = __horizontalLineCounts
        remaindersOnEachEndArray = __remaindersOnEachEndArray
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
