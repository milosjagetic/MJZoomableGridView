open class TilingGridView: UIView
{
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Public properties -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    open var gridProperties: GridProperties = .init()
    {
        didSet
        {
            updateLayoutProperties()
            setNeedsDisplay()
        }
    }
    
    open override class var layerClass: AnyClass
    {
        return NoFadeTiledLayer.self
    }
    

    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Private/Internal properties -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    //there are two identical struct bcs of multithreading. Using only one struct will result in exc_bad_access and all manner of weird unexpected stuff
    private var layoutProperties: LayoutProperties = .init()
    private var _layoutProperties: LayoutProperties = .init()
    
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
        let zoomScale: CGFloat = abs(context.ctm.a) / UIScreen.main.scale
        let adjustedSpacing: CGFloat = CGFloat(gridProperties.pixelsPerLine) / zoomScale
        let adjustedLineWidth: CGFloat = gridProperties.lineWidth / zoomScale
        
        [NSLayoutConstraint.Axis.horizontal, .vertical].forEach({drawLines($0, rect: rect, adjustedSpacing: adjustedSpacing, adjustedLineWidth: adjustedLineWidth, context: context)})
    }

    /// axis = horizontal->draw horizontal line
    open func drawLines(_ axis: NSLayoutConstraint.Axis, rect: CGRect, adjustedSpacing: CGFloat, adjustedLineWidth: CGFloat, context: CGContext)
    {
        let isAxisHorizontal: Bool = axis == .horizontal
        let zoomScale: CGFloat = context.ctm.a / UIScreen.main.scale
        
        //end cases are cases where origin is at the other end (right / bottom depending on the axis). in these cases we shift rendering by a linewidth to make them renderable. not shifting would cause rendering outside bounds
        let isEndCase: Bool = (isAxisHorizontal ? [OriginPlacement.bottomCenter, .bottomLeft, .bottomRight] : [OriginPlacement.topRight, .centerRight, .bottomRight]).contains(gridProperties.originPlacement)
        // if the lines don't line up evenly to view bounds, this is the leftover space, depends on origin placement too
        let remaindersOnEachEnd: UIEdgeInsets = layoutProperties.remaindersOnEachEnd(scale: zoomScale)
        let globalSpacing: CGFloat = (isAxisHorizontal ? remaindersOnEachEnd.top : remaindersOnEachEnd.left)
        //spacing relevant to calculating index/number of lines when rendering
        let spacingForCount: CGFloat = isEndCase ? globalSpacing - adjustedLineWidth : globalSpacing
        //number of lines at the end of given rect
        let maxCount: UInt = UInt(ceil(max(0, (isAxisHorizontal ? rect.maxY : rect.maxX) - spacingForCount) / adjustedSpacing)) + 1
        //number of lines at the begging of given rect
        let prevCount: UInt = UInt(max(0, ceil(max(0, (isAxisHorizontal ? rect.minY : rect.minX) - spacingForCount) / adjustedSpacing) - 1))
        // -1/+1 is added because lines at the beggining of the next tile will be cut in half, so additional line at the end/begginging of the current (also cut in half) is added (this should be changed because it's probably problematic in certain cases)

        //skip rects with no lines
        guard maxCount > prevCount else {return}
        
        // draw lines with indexes contained within the given rect
        for i in prevCount..<maxCount
        {
            var coordinate: CGFloat = CGFloat(i) * adjustedSpacing + globalSpacing
            let relativeCoordinate: CGFloat = isAxisHorizontal ? originRelativeY(for: i, zoomScale: zoomScale, layoutProperties: layoutProperties) : originRelativeX(for: i, zoomScale: zoomScale, layoutProperties: layoutProperties)
            
            // get appropriate attributes for the current line index
            var attributes: LineAttributes?
            if relativeCoordinate == 0 { attributes = isAxisHorizontal ? gridProperties.horizontalAxisAttributes : gridProperties.verticalAxisAttributes }
            if attributes == nil
            {
                attributes = (isAxisHorizontal ? gridProperties.horizontalLineAttributes : gridProperties.verticalLineAttributes)
                    .first(where: {relativeCoordinate.truncatingRemainder(dividingBy: CGFloat($0.divisor) * zoomScale) == 0})
            }

            // determine line width
            let lineWidth: CGFloat = (attributes?.lineWidth ?? gridProperties.lineWidth) / zoomScale
            coordinate += lineWidth >= 1 ? 0 : (adjustedLineWidth / 2)
            
            coordinate -= isEndCase ? 1 : 0

            let lineColor: CGColor = (attributes?.color ?? gridProperties.lineColor).cgColor

            if !isAxisHorizontal && rect.origin.y == 512
            {
//                print("relative: \(relativeCoordinate) coordinate: \(coordinate) maxC: \(maxCount) zs: \(layoutProperties.remaindersOnEachEnd)")
            }
            
            //determine phase offset when cetnering the line dash pattern
            //relative to tile
            let relativePhaseOffset: CGFloat
            if isAxisHorizontal
            {
                switch gridProperties.originPlacement
                {
                case .topCenter, .center, .bottomCenter: relativePhaseOffset = -(attributes?.dashOffsetWhenCentered ?? 0)
                default: relativePhaseOffset = 0
                }
            }
            else
            {
                switch gridProperties.originPlacement
                {
                case .centerLeft, .center, .centerRight: relativePhaseOffset = -(attributes?.dashOffsetWhenCentered ?? 0)
                default: relativePhaseOffset = 0
                }
            }
            //absolute
            let phaseOffset: CGFloat = relativePhaseOffset + (isAxisHorizontal ? rect.minX : rect.minY)

            let tileRange: Range<CGFloat> = isAxisHorizontal ? rect.minX..<rect.maxX : rect.minY..<rect.maxY
            
            //find line segments which have their caps cut off, eg. segments which line segments are rendered on the edges of the tiles
            //draw circles to fix cut off caps
            if attributes?.roundedCap == true
            {
                let halfWidth: CGFloat = lineWidth / 2

                context.setFillColor(lineColor)

                // TOO TIME CONSUMING, THINK OF A BETTER WAY?
                attributes?.lineSegments.forEach
                {
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
                        let x: CGFloat = isAxisHorizontal ? currentCapRange.lowerBound - (isTrailing ? halfWidth : 0) : coordinate - halfWidth
                        let y: CGFloat = isAxisHorizontal ? coordinate - halfWidth : currentCapRange.lowerBound - (isTrailing ? halfWidth : 0)
                        let ellipseFrame: CGRect = CGRect(x: x,
                                                          y: y,
                                                          width: lineWidth,
                                                          height: lineWidth)

                        context.fillEllipse(in: ellipseFrame)
                    }
                }

            }
            
            // actually draw the line
            context.move(to: CGPoint(x: isAxisHorizontal ? rect.origin.x : coordinate, y: isAxisHorizontal ? coordinate : rect.origin.y))
            context.addLine(to: CGPoint(x: isAxisHorizontal ? rect.maxX : coordinate, y: isAxisHorizontal ? coordinate : rect.maxY))

            context.setStrokeColor(lineColor)
            context.setLineDash(phase:  phaseOffset, lengths: attributes?.dashes ?? [])
            context.setLineCap(attributes?.roundedCap == true ? .round : .butt)
            context.setLineWidth(lineWidth)
            
            context.strokePath()
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
        
        drawRandomSquares(rect, context: context)
        drawGrid(rect, context: context)
        
        renderedArea += rect.width * rect.height
        if renderedArea == layoutProperties.boundsArea
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
    
    private func originRelativeX(for absoluteLineIndex: UInt, zoomScale: CGFloat, layoutProperties: LayoutProperties) -> CGFloat
    {
        let n: CGFloat = CGFloat(layoutProperties.verticalLineCount(scale: zoomScale))
        let relativeLineIndex: CGFloat
        switch gridProperties.originPlacement
        {
        case .bottomLeft, .centerLeft, .topLeft: relativeLineIndex = CGFloat(absoluteLineIndex)
        case .bottomRight, .centerRight, .topRight: relativeLineIndex = n - CGFloat(absoluteLineIndex) - 1
        default: relativeLineIndex = CGFloat(absoluteLineIndex) - ceil((n - 1)/2)
        }
        return relativeLineIndex * gridProperties.scale / zoomScale
    }
    
    private func originRelativeY(for absoluteLineIndex: UInt, zoomScale: CGFloat, layoutProperties: LayoutProperties) -> CGFloat
    {
        let n: CGFloat = CGFloat(layoutProperties.horizontalLineCount(scale: zoomScale))
        let relativeLineIndex: CGFloat
        switch gridProperties.originPlacement
        {
        case .topLeft, .topRight, .topCenter: relativeLineIndex = CGFloat(absoluteLineIndex)
        case .bottomLeft, .bottomCenter, .bottomRight: relativeLineIndex = n - CGFloat(absoluteLineIndex) - 1
        default: relativeLineIndex = CGFloat(absoluteLineIndex) - ceil((n - 1)/2)
        }
        return relativeLineIndex * gridProperties.scale / zoomScale
    }
    
    ///Draws a grid of randomly colored squares. Corresponds to placement of tiles. For debug purposes only
    private func drawRandomSquares(_ rect: CGRect, context: CGContext)
    {
        var rect: CGRect = rect
        rect.origin.x = rect.origin.x > layoutProperties.lastReportedBounds.width ? 0 : rect.origin.x
        rect.origin.y = rect.origin.y > layoutProperties.lastReportedBounds.height ? 0 : rect.origin.y
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

        _layoutProperties.calculateLayoutProperties(lastReportedBounds: bounds, tileSideLength: sideLength, pointsPerLine: gridProperties.pixelsPerLine, originPlacement: gridProperties.originPlacement, levelsOfDetail: UInt(layer.levelsOfDetail), zoomInLevels: UInt(layer.levelsOfDetailBias))
        
        layoutProperties = LayoutProperties(lastReportedBounds: _layoutProperties.lastReportedBounds, boundsArea: _layoutProperties.boundsArea, verticalLineCounts: _layoutProperties.verticalLineCounts, horizontalLineCounts: _layoutProperties.horizontalLineCounts, remaindersOnEachEndArray: _layoutProperties.remaindersOnEachEndArray)

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
