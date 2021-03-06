//
//  LayoutProperties.swift
//  MJGridView
//
//  Created by Milos Jagetic on 16/09/2019.
//

import Foundation


///This struct contains properties which are constant for each layout of the UI. For performance reasons they are calculated once per layout and stored here just to keep things tidy
// Maybe change it to class. Maybe it will make multithreading harder
internal struct LayoutSnapshot
{
    private(set) var lastReportedBounds: CGRect = .zero
    private(set) var boundsArea: CGFloat = 0
    
    var lineSpacing: CGFloat {CGFloat(gridProperties.lineSpacing)}
    
    // TODO: Do something about this Atomic and double proprties voodoo
    @Atomic private(set) var verticalLineCounts: [CGFloat : UInt] = [:]
    @Atomic private(set) var horizontalLineCounts: [CGFloat : UInt] = [:]
    @Atomic private(set) var remaindersOnEachEndArray: [CGFloat : UIEdgeInsets] = [:]
    
    private(set) var __verticalLineCounts: [CGFloat : UInt] = [:]
    private(set) var __horizontalLineCounts: [CGFloat : UInt] = [:]
    private(set) var __remaindersOnEachEndArray: [CGFloat : UIEdgeInsets] = [:]
    
    private(set) var gridProperties: GridProperties = .init()
    
    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Lifecycle protocol implementation -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    init() {}
    
    init(lastReportedBounds: CGRect,
         boundsArea: CGFloat,
         verticalLineCounts: [CGFloat : UInt],
         horizontalLineCounts: [CGFloat : UInt],
         remaindersOnEachEndArray: [CGFloat : UIEdgeInsets],
         gridProperties: GridProperties)
    {
        self.lastReportedBounds = lastReportedBounds
        self.boundsArea = boundsArea
        self.verticalLineCounts = verticalLineCounts
        self.horizontalLineCounts = horizontalLineCounts
        self.remaindersOnEachEndArray = remaindersOnEachEndArray
        self.gridProperties = gridProperties.copy()
    }
    
    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Layout -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    mutating func calculateLayoutProperties(lastReportedBounds: CGRect,
                                            levelsOfDetail: UInt,
                                            zoomInLevels: UInt,
                                            gridProperties: GridProperties)
    {
        self.lastReportedBounds = lastReportedBounds
        self.gridProperties = gridProperties.copy()
        
        boundsArea = lastReportedBounds.width * lastReportedBounds.height

        __verticalLineCounts = Dictionary<CGFloat, UInt>()
        __horizontalLineCounts = Dictionary<CGFloat, UInt>()
        __remaindersOnEachEndArray = Dictionary<CGFloat, UIEdgeInsets>()
                
        let zoomOutLevels: UInt = levelsOfDetail - zoomInLevels - 1
        let originPlacement: OriginPlacement = gridProperties.originPlacement
        
        for currentLevel in 0..<levelsOfDetail
        {
            var remaindersOnEachEnd: UIEdgeInsets = .zero
            var verticalLineCount: UInt = 0
            var horizontalLineCount: UInt = 0

            let relativeLevel: Double = Double(currentLevel) - Double(zoomOutLevels)
            let zoomScale: CGFloat = CGFloat(pow(2, relativeLevel))
            
            let pointsPerLine: CGFloat = CGFloat(gridProperties.lineSpacing) / zoomScale
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
            case .custom(let point):
                remaindersOnEachEnd.left = point.x.truncatingRemainder(dividingBy: pointsPerLine)
                remaindersOnEachEnd.right = (targetWidth - point.x).truncatingRemainder(dividingBy: pointsPerLine)
            }
            
            //line count
            switch originPlacement
            {
            case .topCenter, .center, .bottomCenter, .custom(_):
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
            case .custom(let point):
                remaindersOnEachEnd.top = point.y.truncatingRemainder(dividingBy: pointsPerLine)
                remaindersOnEachEnd.bottom = (targetHeight - point.y).truncatingRemainder(dividingBy: pointsPerLine)
            }
            
            
            //line count
            switch originPlacement
            {
            case .centerLeft, .center, .centerRight, .custom(_):
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
    
    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Accessors -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
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
    
    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Copy -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    func copy() -> LayoutSnapshot
    {
        return .init(lastReportedBounds: lastReportedBounds,
                     boundsArea: boundsArea,
                     verticalLineCounts: verticalLineCounts,
                     horizontalLineCounts: horizontalLineCounts,
                     remaindersOnEachEndArray: remaindersOnEachEndArray,
                     gridProperties: gridProperties)
    }
}

@propertyWrapper
struct Atomic<Value>
{
    private var value: Value
    private let lock = NSLock()

    init(wrappedValue value: Value)
    {
        self.value = value
    }

    var wrappedValue: Value
    {
      get { return load() }
      set { store(newValue: newValue) }
    }

    func load() -> Value
    {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    mutating func store(newValue: Value)
    {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}
