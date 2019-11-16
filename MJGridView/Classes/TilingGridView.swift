private extension UIColor
{
    static var randomOpaque: UIColor
    {
        return UIColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1)
    }
}

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
    internal var layoutProperties: LayoutProperties = .init()

    private let sideLength: CGFloat = 46

    
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
        //TODO: make dependent on zoom
        layer.levelsOfDetail = 4
        layer.levelsOfDetailBias = 3
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
        let globalSpacing: CGFloat = (isAxisHorizontal ? layoutProperties.remaindersOnEachEnd.top : layoutProperties.remaindersOnEachEnd.left) / zoomScale
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
            let relativeCoordinate: CGFloat = isAxisHorizontal ? originRelativeY(for: i, zoomScale: zoomScale) : originRelativeX(for: i, zoomScale: zoomScale)
            
            // get appropriate attributes for the current line index
            var attributes: LineAttributes?
            if relativeCoordinate == 0 { attributes = isAxisHorizontal ? gridProperties.horizontalAxisAttributes : gridProperties.verticalAxisAttributes }
            if attributes == nil
            {
                attributes = (isAxisHorizontal ? gridProperties.horizontalLineAttributes : gridProperties.verticalLineAttributes)
                    .first(where: {relativeCoordinate.truncatingRemainder(dividingBy: CGFloat($0.divisor) * zoomScale) == 0})
            }

            // determine line width
            let lineWidth: CGFloat = attributes?.lineWidth ?? gridProperties.lineWidth
            coordinate += lineWidth > 1 ? 0 : (adjustedLineWidth / 2)
            
            // TODO: if line width too big can be rendered outside
            coordinate -= isEndCase ? 1 : 0
//            if isAxisHorizontal { print(coordinate)}
            // actually draw the line
            context.move(to: CGPoint(x: isAxisHorizontal ? rect.origin.x : coordinate, y: isAxisHorizontal ? coordinate : rect.origin.y))
            context.addLine(to: CGPoint(x: isAxisHorizontal ? rect.maxX : coordinate, y: isAxisHorizontal ? coordinate : rect.maxY))
            
            context.setStrokeColor((attributes?.color ?? gridProperties.lineColor).cgColor)
            context.setLineDash(phase: 0, lengths: attributes?.dashes.map({$0 / zoomScale}) ?? [])
            context.setLineWidth(lineWidth / zoomScale)
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
    }

    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Private -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    private func originRelativeX(for absoulteX: CGFloat, globalSpacing: CGFloat) -> CGFloat
    {
        let correction: CGFloat
        switch gridProperties.originPlacement
        {
        case .bottomRight, .centerRight, .topRight: correction = globalSpacing
        case .bottomLeft, .centerLeft, .topLeft: correction = -globalSpacing
        default: correction = 0
        }
        return (absoulteX + correction - gridProperties.originPlacement.origin(in: layoutProperties.lastReportedBounds).x) / gridProperties.scale
    }
    
    private func originRelativeX(for absoluteLineIndex: UInt, zoomScale: CGFloat) -> CGFloat
    {
        let n: CGFloat = CGFloat(layoutProperties.verticalLineCount) * zoomScale
        let relativeLineIndex: CGFloat
        switch gridProperties.originPlacement
        {
        case .bottomLeft, .centerLeft, .topLeft: relativeLineIndex = CGFloat(absoluteLineIndex)
        case .bottomRight, .centerRight, .topRight: relativeLineIndex = n - CGFloat(absoluteLineIndex) - 1
        default: relativeLineIndex = CGFloat(absoluteLineIndex) - ((n - (layoutProperties.verticalLineCount.isMultiple(of: 2) ? 0 : 1 * zoomScale)) / 2)
        }
        return CGFloat(relativeLineIndex) * gridProperties.scale
    }
    
    private func originRelativeY(for absoluteLineIndex: UInt, zoomScale: CGFloat) -> CGFloat
    {
        let n: CGFloat = CGFloat(layoutProperties.horizontalLineCount) * zoomScale
        let relativeLineIndex: CGFloat
        switch gridProperties.originPlacement
        {
        case .topLeft, .topRight, .topCenter: relativeLineIndex = CGFloat(absoluteLineIndex)
        case .bottomLeft, .bottomCenter, .bottomRight: relativeLineIndex = n - CGFloat(absoluteLineIndex) - 1
        default: relativeLineIndex = CGFloat(absoluteLineIndex) - ((n - (layoutProperties.horizontalLineCount.isMultiple(of: 2) ? 0 : 1 * zoomScale)) / 2) //TODO: Maybe change this relies on line count to be odd
        }
        return relativeLineIndex * gridProperties.scale
    }

    private func originRelativeY(for absoluteY: CGFloat, globalSpacing: CGFloat) -> CGFloat
    {
        let correction: CGFloat
        switch gridProperties.originPlacement
        {
        case .topLeft, .topCenter, .topRight: correction = -globalSpacing
        case .bottomLeft, .bottomRight, .bottomCenter: correction = globalSpacing
        default: correction = 0
        }
        return (absoluteY + correction - gridProperties.originPlacement.origin(in: layoutProperties.lastReportedBounds).y) / gridProperties.scale
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
        layoutProperties.calculateLayoutProperties(lastReportedBounds: bounds, tileSideLength: sideLength, pointsPerLine: gridProperties.pixelsPerLine, originPlacement: gridProperties.originPlacement)
    }
}
