open class TilingGridView: UIView
{
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Public properties -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    /// Main configuration thingie. Use this to change grid properties. See each properties documentation for more details.
    open var gridProperties: GridProperties = .init()
    {
        didSet
        {
            updateLayoutProperties()
            setNeedsDisplay()
        }
    }
    /// Log debug level. See each case for more details
    open var debugLevel: DebugLevel = .none {didSet {setNeedsDisplay()}}
    /// Class used for tiling. You can use your own if you want to change fade duration or something.
    open override class var layerClass: AnyClass
    {
        return NoFadeTiledLayer.self
    }
    

    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Private/Internal properties -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    //there are two identical struct bcs of multithreading. Using only one struct will result in exc_bad_access and all manner of weird unexpected stuff. While __layoutProperties is being mutated layoutProperties is used for rendering, once mutated it is assigned to layoutProperties to be used.
    private var layoutSnapshot: LayoutSnapshot
    {
        DispatchQueue.main.sync
        {
            return __layoutSnapshot
        }
    }
    private var __layoutSnapshot: LayoutSnapshot = .init()
    
    private let sideLength: CGFloat = 256
    private var startedRenderingDate: Date = Date()
    private var renderedArea: CGFloat = 0
    private var averageTme: TimeInterval = 0
    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Lifecycle -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    public override init(frame: CGRect)
    {
        super.init(frame: frame)
        myinit()
    }
    
    public required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        myinit()
    }
    
    open func myinit()
    {
        guard let layer: CATiledLayer = self.layer as? CATiledLayer else {return}
        
        let scale: CGFloat = UIScreen.main.scale
        layer.contentsScale = scale
        layer.tileSize = CGSize(width: sideLength * scale, height: sideLength * scale)
    }

    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Public -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    open func drawGrid(_ rect: CGRect, context: CGContext)
    {
        let layoutSnapshot: LayoutSnapshot = self.layoutSnapshot.copy()

        let zoomScale: CGFloat = abs(context.ctm.a) / UIScreen.main.scale
        let adjustedSpacing: CGFloat = layoutSnapshot.lineSpacing / zoomScale
        
        //maybe attach this to layout properties aswell
        let adjustedLineWidth: CGFloat = layoutSnapshot.gridProperties.lineWidth / zoomScale
        

        [NSLayoutConstraint.Axis.horizontal, .vertical].forEach({drawLines($0, rect: rect, adjustedSpacing: adjustedSpacing, adjustedLineWidth: adjustedLineWidth, context: context, layoutSnapshot: layoutSnapshot)})
    }

    /// axis = horizontal->draw horizontal line
    private func drawLines(_ axis: NSLayoutConstraint.Axis, rect: CGRect, adjustedSpacing: CGFloat, adjustedLineWidth: CGFloat, context: CGContext, layoutSnapshot: LayoutSnapshot)
    {
        let gridProperties: GridProperties = layoutSnapshot.gridProperties
        let isLineHorizontal: Bool = axis == .horizontal
        let zoomScale: CGFloat = context.ctm.a / UIScreen.main.scale
        let originPlacement: OriginPlacement = gridProperties.originPlacement
        
        //end cases are cases where origin is at the other end (right / bottom depending on the axis). in these cases we shift rendering by a linewidth to make them renderable. not shifting would cause rendering outside bounds
        let isEndCase: Bool = (isLineHorizontal ? [OriginPlacement.bottomCenter, .bottomLeft, .bottomRight] : [OriginPlacement.topRight, .centerRight, .bottomRight]).contains(originPlacement)
        // if the lines don't line up evenly to view bounds, this is the leftover space, depends on origin placement too
        let remaindersOnEachEnd: UIEdgeInsets = layoutSnapshot.remaindersOnEachEnd(scale: zoomScale)
        let globalSpacing: CGFloat = (isLineHorizontal ? remaindersOnEachEnd.top : remaindersOnEachEnd.left)
        //spacing relevant to calculating index/number of lines when rendering
        let spacingForCount: CGFloat = isEndCase ? globalSpacing - adjustedLineWidth : globalSpacing
        //number of lines at the end of given rect
        let maxCount: UInt = UInt(ceil(max(0, (isLineHorizontal ? rect.maxY : rect.maxX) - spacingForCount) / adjustedSpacing)) + 1
        //number of lines at the begging of given rect
        let prevCount: UInt = UInt(max(0, ceil(max(0, (isLineHorizontal ? rect.minY : rect.minX) - spacingForCount) / adjustedSpacing) - 1))
        // -1/+1 is added because lines at the beggining of the next tile will be cut in half, so additional line at the end/begginging of the current (also cut in half) is added (this should be changed because it's probably problematic in certain cases)

        //skip rects with no lines
        guard maxCount > prevCount else {return}
        
        // draw lines with indexes contained within the given rect
        for i in prevCount..<maxCount
        {
            var coordinate: CGFloat = CGFloat(i) * adjustedSpacing + globalSpacing
            let relativeCoordinate: CGFloat = isLineHorizontal ? originRelativeY(for: i, zoomScale: zoomScale, layoutSnapshot: layoutSnapshot) : originRelativeX(for: i, zoomScale: zoomScale, layoutSnapshot: layoutSnapshot)
            
            // get appropriate attributes for the current line index
            var attributes: LineAttributes?
            if relativeCoordinate == 0 { attributes = isLineHorizontal ? gridProperties.horizontalAxisAttributes : gridProperties.verticalAxisAttributes }
            if attributes == nil
            {
                attributes = (isLineHorizontal ? gridProperties.horizontalLineAttributes : gridProperties.verticalLineAttributes)
                    .first(where: {relativeCoordinate.truncatingRemainder(dividingBy: CGFloat($0.divisor)) == 0})
            }

            // determine line width
            let lineWidth: CGFloat = (attributes?.lineWidth ?? gridProperties.lineWidth) / zoomScale
            coordinate += lineWidth >= 1 ? 0 : (adjustedLineWidth / 2)
            
            coordinate -= isEndCase ? 1 : 0

            let lineColor: CGColor = (attributes?.color ?? gridProperties.lineColor).cgColor
            
            //draw cutoff line caps
            drawCutOffLineCaps(in: rect,
                               isLineHorizontal: isLineHorizontal,
                               originPlacement: originPlacement,
                               context: context,
                               lineWidth: lineWidth,
                               lineColor: lineColor,
                               coordinate: coordinate,
                               attributes: attributes)

            // actually draw the line
            context.move(to: CGPoint(x: isLineHorizontal ? rect.origin.x : coordinate, y: isLineHorizontal ? coordinate : rect.origin.y))
            context.addLine(to: CGPoint(x: isLineHorizontal ? rect.maxX : coordinate, y: isLineHorizontal ? coordinate : rect.maxY))

            context.setStrokeColor(lineColor)
            context.setLineCap(attributes?.roundedCap == true ? .round : .butt)
            context.setLineWidth(lineWidth)
            
            context.strokePath()
                        
            // draw labels
            drawLabels(in: rect,
                       coordinate: coordinate,
                       relativeCoordinate: relativeCoordinate,
                       zoomScale: zoomScale,
                       isDrawingHorizontalLines: isLineHorizontal,
                       layoutSnapshot: layoutSnapshot)
        }
    }
    
    private func drawCutOffLineCaps(in rect: CGRect,
                                    isLineHorizontal: Bool,
                                    originPlacement: OriginPlacement,
                                    context: CGContext,
                                    lineWidth: CGFloat,
                                    lineColor: CGColor,
                                    coordinate: CGFloat,
                                    attributes: LineAttributes?)
    {
        //determine phase offset when cetnering the line dash pattern
        //relative to tile
        let relativePhaseOffset: CGFloat
        if isLineHorizontal
        {
            switch originPlacement
            {
            case .topCenter, .center, .bottomCenter: relativePhaseOffset = -(attributes?.dashOffsetWhenCentered ?? 0)
            default: relativePhaseOffset = 0
            }
        }
        else
        {
            switch originPlacement
            {
            case .centerLeft, .center, .centerRight: relativePhaseOffset = -(attributes?.dashOffsetWhenCentered ?? 0)
            default: relativePhaseOffset = 0
            }
        }
        //absolute
        let phaseOffset: CGFloat = relativePhaseOffset + (isLineHorizontal ? rect.minX : rect.minY)

        let tileRange: Range<CGFloat> = isLineHorizontal ? rect.minX..<rect.maxX : rect.minY..<rect.maxY
        
        //find line segments which have their caps cut off, eg. segments which line segments are rendered on the edges of the tiles
        //draw circles to fix cut off caps
        //!!!! bad access here (xA) (most likely fixed by moving gridProperties under LayoutSnapshot, but the comment remains if any more crashes happen)
        if attributes?.roundedCap == true
        {
            let halfWidth: CGFloat = lineWidth / 2

            context.setFillColor(lineColor)

            // TOO TIME CONSUMING, THINK OF A BETTER WAY?
            //!!!! bad access here (xB)(most likely fixed by moving gridProperties under LayoutSnapshot, but the comment remains if any more crashes happen)
            attributes?.lineSegments.forEach
            {
                //!!!! out of bounds crash. Probably related to (xA) and (xB), fix: move grid properties under layout properties (xC)(most likely fixed by moving gridProperties under LayoutSnapshot, but the comment remains if any more crashes happen)
                let offsetLineSegment: Range<CGFloat> = ($0.lowerBound - relativePhaseOffset)..<($0.upperBound - relativePhaseOffset)
                let leadingCapRange: Range<CGFloat> = (offsetLineSegment.lowerBound - halfWidth)..<offsetLineSegment.lowerBound
                let trailingCapRange: Range<CGFloat> = offsetLineSegment.upperBound..<(offsetLineSegment.upperBound + halfWidth)

                
                for currentCapRange in [leadingCapRange, trailingCapRange]
                {
                    let currentOverlap: CGFloat = currentCapRange.clamped(to: tileRange).magnitude
                    //do only caps within our tile && do only caps for lines outside the tile (caps that have actually been clipped)
                    guard currentOverlap > 0 && !offsetLineSegment.overlaps(tileRange) else {continue}
//
                    let isTrailing: Bool = currentCapRange == trailingCapRange
                    let x: CGFloat = isLineHorizontal ? currentCapRange.lowerBound - (isTrailing ? halfWidth : 0) : coordinate - halfWidth
                    let y: CGFloat = isLineHorizontal ? coordinate - halfWidth : currentCapRange.lowerBound - (isTrailing ? halfWidth : 0)
                    let ellipseFrame: CGRect = CGRect(x: x,
                                                      y: y,
                                                      width: lineWidth,
                                                      height: lineWidth)

                    context.fillEllipse(in: ellipseFrame)
                }
            }

        }
        
        context.setLineDash(phase:  phaseOffset, lengths: attributes?.dashes ?? [])
    }
    
    private func drawLabels(in rect: CGRect, coordinate: CGFloat, relativeCoordinate: CGFloat, zoomScale: CGFloat, isDrawingHorizontalLines: Bool, layoutSnapshot: LayoutSnapshot)
    {
        // skips horiontal axis label for relative coordinate 0, to avoid duplicates
        guard isDrawingHorizontalLines || relativeCoordinate != 0 else {return}
        
        let originPosition: CGPoint = gridProperties.originPlacement.origin(in: layoutSnapshot.lastReportedBounds)

        var labelAttributes: [NSAttributedString.Key : Any] = isDrawingHorizontalLines ? gridProperties.verticalAxisLabelAttributes : gridProperties.horizontalAxisLabelAttributes
        if let font = labelAttributes[.font] as? UIFont
        {
            labelAttributes[.font] = font.withSize(font.pointSize / zoomScale)
        }

        let attrString: NSAttributedString = .init(string: String(format: (isDrawingHorizontalLines ? gridProperties.verticalAxisLabelFormat : gridProperties.horizontalAxisLabelFormat), relativeCoordinate == 0 ? 0 : relativeCoordinate), attributes: labelAttributes)
        let size: CGSize = attrString.size()

        var horizontalOffset: CGFloat = isDrawingHorizontalLines ? (gridProperties.verticalAxisLabelInsets.left - gridProperties.verticalAxisLabelInsets.right) : (gridProperties.horizontalAxisLabelInsets.left - gridProperties.horizontalAxisLabelInsets.right)
        horizontalOffset /= zoomScale
        
        var verticalOffset: CGFloat = isDrawingHorizontalLines ? (gridProperties.verticalAxisLabelInsets.top - gridProperties.verticalAxisLabelInsets.bottom) : (gridProperties.horizontalAxisLabelInsets.top - gridProperties.horizontalAxisLabelInsets.bottom)
        verticalOffset /= zoomScale

        if isDrawingHorizontalLines
        {
            if (rect.minX..<rect.maxX).contains(originPosition.x) ||
                (rect.minX - (originPosition.x + horizontalOffset) < size.width) ||
                (rect.minY - (coordinate + verticalOffset) < size.height)
            {
                let stringRect: CGRect = .init(x: (isDrawingHorizontalLines ? originPosition.x : coordinate) + horizontalOffset, y: (isDrawingHorizontalLines ? coordinate : originPosition.y) + verticalOffset, width: size.width, height: size.height)
                attrString.draw(in: stringRect)
            }
        }
        else
        {
            if (rect.minY..<rect.maxY).contains(originPosition.y) ||
                (rect.minY - (originPosition.y + verticalOffset) < size.height) ||
                (rect.minX - (coordinate + horizontalOffset) < size.width)
            {
                let stringRect: CGRect = .init(x: (isDrawingHorizontalLines ? originPosition.x : coordinate) + horizontalOffset, y: (isDrawingHorizontalLines ? coordinate : originPosition.y) + verticalOffset, width: size.width, height: size.height)
                attrString.draw(in: stringRect)

            }
        }

    }


    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Overriden -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    open override func layoutSubviews()
    {
        super.layoutSubviews()
        
        updateLayoutProperties()
        setNeedsDisplay()
    }
    
    open override func draw(_ rect: CGRect)
    {
        guard let context: CGContext = UIGraphicsGetCurrentContext() else {return}
        context.saveGState()
        defer {context.restoreGState()}
        
        if debugLevel.rawValue >= DebugLevel.randomSquares.rawValue
        {
            drawRandomSquares(rect, context: context)
        }
        
        drawGrid(rect, context: context)
        
        guard debugLevel.rawValue >= DebugLevel.performanceAnalysis.rawValue else {return}
        
        renderedArea += rect.width * rect.height
        if renderedArea == layoutSnapshot.boundsArea
        {
            let time: TimeInterval = Date().timeIntervalSince(startedRenderingDate)
            averageTme = averageTme == 0 ? time : (averageTme + time) / 2
            
            print(String(format: "+++time %.4f, average: %.3f", time, averageTme))
        }
    }
    
    open override func setNeedsDisplay()
    {
        super.setNeedsDisplay()
        
        startedRenderingDate = Date()
        renderedArea = 0
        
        guard debugLevel.rawValue >= DebugLevel.performanceAnalysis.rawValue else {return}
        print("--- needs display")
    }

    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Private/Internal -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    internal func updateLevelsOfDetail(minZoom: CGFloat, maxZoom: CGFloat)
    {
        guard let layer = self.layer as? NoFadeTiledLayer else {return}
        
        let zoomInLevelsOfDetail: Int = Int(ceil(log2(maxZoom)))
        let zoomOutLevelsOfDetail: Int = Int(ceil(abs(log2(minZoom))))
        
        layer.levelsOfDetail = zoomInLevelsOfDetail + zoomOutLevelsOfDetail + 1
        layer.levelsOfDetailBias = zoomInLevelsOfDetail
        
        setNeedsDisplay()
    }
    
    private func originRelativeX(for absoluteLineIndex: UInt, zoomScale: CGFloat, layoutSnapshot: LayoutSnapshot) -> CGFloat
    {
        let n: CGFloat = CGFloat(layoutSnapshot.verticalLineCount(scale: zoomScale))
        let relativeLineIndex: CGFloat
        switch layoutSnapshot.gridProperties.originPlacement
        {
        case .bottomLeft, .centerLeft, .topLeft: relativeLineIndex = CGFloat(absoluteLineIndex)
        case .bottomRight, .centerRight, .topRight: relativeLineIndex = n - CGFloat(absoluteLineIndex) - 1
        case .custom(let point):
            let remainders: UIEdgeInsets = layoutSnapshot.remaindersOnEachEnd(scale: zoomScale)
            relativeLineIndex = CGFloat(absoluteLineIndex) - ceil((point.x - remainders.left - remainders.right) / (CGFloat(layoutSnapshot.gridProperties.pixelsPerLine) / zoomScale))

        default: relativeLineIndex = CGFloat(absoluteLineIndex) - ceil((n - 1)/2)
        }
        return relativeLineIndex * layoutSnapshot.gridProperties.horizontalScale / zoomScale
    }
    
    private func originRelativeY(for absoluteLineIndex: UInt, zoomScale: CGFloat, layoutSnapshot: LayoutSnapshot) -> CGFloat
    {
        let n: CGFloat = CGFloat(layoutSnapshot.horizontalLineCount(scale: zoomScale))
        let relativeLineIndex: CGFloat
        switch layoutSnapshot.gridProperties.originPlacement
        {
        case .topLeft, .topRight, .topCenter: relativeLineIndex = CGFloat(absoluteLineIndex)
        case .bottomLeft, .bottomCenter, .bottomRight: relativeLineIndex = n - CGFloat(absoluteLineIndex) - 1
        case .custom(let point):
            let remainders: UIEdgeInsets = layoutSnapshot.remaindersOnEachEnd(scale: zoomScale)
            relativeLineIndex = CGFloat(absoluteLineIndex) - ceil((point.y - remainders.top - remainders.bottom) / (CGFloat(layoutSnapshot.gridProperties.pixelsPerLine) / zoomScale))
        default: relativeLineIndex = CGFloat(absoluteLineIndex) - ceil((n - 1)/2)
        }
        return relativeLineIndex * layoutSnapshot.gridProperties.verticalScale / zoomScale
    }
    
    ///Draws a grid of randomly colored squares. Corresponds to placement of tiles. For debug purposes only
    private func drawRandomSquares(_ rect: CGRect, context: CGContext)
    {
        var rect: CGRect = rect
        rect.origin.x = rect.origin.x > layoutSnapshot.lastReportedBounds.width ? 0 : rect.origin.x
        rect.origin.y = rect.origin.y > layoutSnapshot.lastReportedBounds.height ? 0 : rect.origin.y
        context.setFillColor(UIColor.randomOpaque.withAlphaComponent(0.3).cgColor)
        context.fill(rect)
    }
    
    private func updateLayoutProperties()
    {
        let bounds: CGRect = self.bounds
        
        //Line segments are needed for dashed lines
        ([gridProperties.horizontalAxisAttributes] + gridProperties.horizontalLineAttributes).forEach({$0?.calculateLineSegments(maxOffset: bounds.width)})
        ([gridProperties.verticalAxisAttributes] + gridProperties.verticalLineAttributes).forEach({$0?.calculateLineSegments(maxOffset: bounds.height)})
        
        guard let layer: CATiledLayer = self.layer as? CATiledLayer else {return}

        __layoutSnapshot.calculateLayoutProperties(lastReportedBounds: bounds, levelsOfDetail: UInt(layer.levelsOfDetail), zoomInLevels: UInt(layer.levelsOfDetailBias), gridProperties: gridProperties)
    }
}


//  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
//  MARK: Helpers -
//  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
private extension UIColor
{
    static var randomOpaque: UIColor
    {
        return UIColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1)
    }
}

private extension Range
where Bound == CGFloat
{
    var magnitude: CGFloat
    {
        return upperBound - lowerBound
    }
}
