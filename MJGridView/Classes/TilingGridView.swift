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
    open var horizontalLineAttributes: [LineAttributes] = [LineAttributes(color: .red, divisor: 3, dashes: [16, 16], lineWidth: 5)]
    open var horintalAxisAttributes: LineAttributes? = LineAttributes(color: .green, divisor: 0, dashes: [], lineWidth: 10)
    open var verticalLineAttributes: [LineAttributes] = [LineAttributes(color: .blue, divisor: 3, dashes: [], lineWidth: 1)]
    open var verticalAxisAttributes: LineAttributes? = LineAttributes(color: .cyan, divisor: 0, dashes: [], lineWidth: 10)
    
    open var originPlacement: OriginPlacement = .center
    {
        didSet
        {
            updateLayoutProperties()
            setNeedsDisplay()
        }
    }
    
    open var pixelsPerLine: UInt = 112 { didSet { updateLayoutProperties() } }
    
    open var lineWidth: CGFloat = 1 / UIScreen.main.scale
    
    open var lineColor: UIColor = .black
    
    open var scale: CGFloat = 20
    
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
        layer.levelsOfDetail = 4
        layer.levelsOfDetailBias = 3
    }

    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Public -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    open func drawGrid(_ rect: CGRect, context: CGContext)
    {
        let zoomScale: CGFloat = abs(context.ctm.a) / UIScreen.main.scale
        let adjustedSpacing: CGFloat = CGFloat(pixelsPerLine) / zoomScale
        let adjustedLineWidth: CGFloat = lineWidth / zoomScale
        
//        drawVerticalLines(in: rect, adjustedSpacing: adjustedSpacing, adjustedLineWidth: adjustedLineWidth, context: context)
//        drawHorizontalLines(in: rect, adjustedSpacing: adjustedSpacing, adjustedLineWidth: adjustedLineWidth, context: context)
        [NSLayoutConstraint.Axis.horizontal, .vertical].forEach({drawLines($0, rect: rect, adjustedSpacing: adjustedSpacing, adjustedLineWidth: adjustedLineWidth, context: context)})
    }
    
    open func drawVerticalLines(in rect: CGRect, adjustedSpacing: CGFloat, adjustedLineWidth: CGFloat, context: CGContext)
    {
        let zoomScale: CGFloat = context.ctm.a / UIScreen.main.scale
        
        let isEndCase: Bool = [OriginPlacement.topRight, .centerRight, .bottomRight].contains(originPlacement)
        let globalSpacing: CGFloat = layoutProperties.remaindersOnEachEnd.left
        
        let spacingForCount: CGFloat = isEndCase ? globalSpacing - adjustedLineWidth : globalSpacing
        let maxCount: Int = Int(ceil((rect.maxX - spacingForCount) / adjustedSpacing))
        let prevCount: Int = Int(ceil(max(0, rect.minX - spacingForCount) / adjustedSpacing))
        
        guard maxCount > prevCount else {return}
        
        for i in prevCount..<(maxCount + 1)
        {
            var x: CGFloat = CGFloat(i) * adjustedSpacing + globalSpacing
            
            let relativeX: CGFloat = originRelativeX(for: x, globalSpacing: isEndCase ? layoutProperties.remaindersOnEachEnd.right : layoutProperties.remaindersOnEachEnd.left)

            var attributes: LineAttributes?
            if relativeX == 0 { attributes = verticalAxisAttributes }
            if attributes == nil { attributes = verticalLineAttributes.first(where: {relativeX.truncatingRemainder(dividingBy: CGFloat($0.divisor)) == 0}) }

            let lineWidth: CGFloat = attributes?.lineWidth ?? self.lineWidth
            x += lineWidth > 1 ? 0 : (adjustedLineWidth / 2)
            
            x -= isEndCase ? .leastNormalMagnitude : 0

            context.move(to: CGPoint(x:  x, y: rect.origin.y))
            context.addLine(to: CGPoint(x: x, y: rect.maxY))
            
            
            context.setStrokeColor((attributes?.color ?? lineColor).cgColor)
            context.setLineDash(phase: 0, lengths: attributes?.dashes.map({$0 / zoomScale}) ?? [])
            context.setLineWidth(lineWidth / zoomScale)
            
            context.strokePath()
        }
    }
    
    open func drawLines(_ axis: NSLayoutConstraint.Axis, rect: CGRect, adjustedSpacing: CGFloat, adjustedLineWidth: CGFloat, context: CGContext)
    {
        let isAxisHorizontal: Bool = axis == .horizontal
        let zoomScale: CGFloat = context.ctm.a / UIScreen.main.scale
        
        let isEndCase: Bool = (isAxisHorizontal ? [OriginPlacement.bottomCenter, .bottomLeft, .bottomRight] : [OriginPlacement.topRight, .centerRight, .bottomRight]).contains(originPlacement)
        
        let globalSpacing: CGFloat = isAxisHorizontal ? layoutProperties.remaindersOnEachEnd.top : layoutProperties.remaindersOnEachEnd.left
        let spacingForCount: CGFloat = isEndCase ? globalSpacing - adjustedLineWidth : globalSpacing

        let maxCount: UInt = UInt(ceil(max(0, (isAxisHorizontal ? rect.maxY : rect.maxX) - spacingForCount) / adjustedSpacing))
        let prevCount: UInt = UInt(ceil(max(0, (isAxisHorizontal ? rect.minY : rect.minX) - spacingForCount) / adjustedSpacing))
        
        guard maxCount > prevCount else {return}
        
        for i in prevCount..<(maxCount + 1)
        {
            var coordinate: CGFloat = CGFloat(i) * adjustedSpacing + globalSpacing
            let relativeCoordinate: CGFloat = isAxisHorizontal ?
                originRelativeY(for: coordinate, globalSpacing: isEndCase ? layoutProperties.remaindersOnEachEnd.bottom : layoutProperties.remaindersOnEachEnd.top)
                : originRelativeX(for: coordinate, globalSpacing: isEndCase ? layoutProperties.remaindersOnEachEnd.right : layoutProperties.remaindersOnEachEnd.left)
            
            var attributes: LineAttributes?
            if relativeCoordinate == 0 { attributes = isAxisHorizontal ? horintalAxisAttributes : verticalAxisAttributes }
            if attributes == nil
            {
                attributes = (isAxisHorizontal ? horizontalLineAttributes : verticalLineAttributes)
                    .first(where: {relativeCoordinate.truncatingRemainder(dividingBy: CGFloat($0.divisor)) == 0})
            }
            
            let lineWidth: CGFloat = attributes?.lineWidth ?? self.lineWidth
            coordinate += lineWidth > 1 ? 0 : (adjustedLineWidth / 2)
            
            coordinate -= isEndCase ? .leastNormalMagnitude : 0
            
            context.move(to: CGPoint(x: isAxisHorizontal ? rect.origin.x : coordinate, y: isAxisHorizontal ? coordinate : rect.origin.y))
            context.addLine(to: CGPoint(x: isAxisHorizontal ? rect.maxX : coordinate, y: isAxisHorizontal ? coordinate : rect.maxY))
            
            context.setStrokeColor((attributes?.color ?? lineColor).cgColor)
            context.setLineDash(phase: 0, lengths: attributes?.dashes.map({$0 / zoomScale}) ?? [])
            context.setLineWidth(lineWidth / zoomScale)
            context.strokePath()
        }
    }
    
    open func drawHorizontalLines(in rect: CGRect, adjustedSpacing: CGFloat, adjustedLineWidth: CGFloat, context: CGContext)
    {
        let zoomScale: CGFloat = context.ctm.a / UIScreen.main.scale
        
        //end cases are cases where origin is at the other end (right / bottom depending on the axis)
        let isEndCase: Bool = [OriginPlacement.bottomCenter, .bottomLeft, .bottomRight].contains(originPlacement)
        // if the lines don't line up evenly to view bounds, this is the leftover space, depends on origin placement too
        // if the origin is at the "end" of the axis, it actually ends up "after the end", move it back by the line width
        let globalSpacing: CGFloat = layoutProperties.remaindersOnEachEnd.top
        // index of the last line in the rect
        let maxCount: Int = Int(ceil((rect.maxY - (isEndCase ? globalSpacing - adjustedLineWidth : globalSpacing)) / adjustedSpacing))
        // index of the last line in the 'previous' rect
        let prevCount: Int = Int(ceil(max(0, rect.minY - (isEndCase ? globalSpacing - adjustedLineWidth : globalSpacing)) / adjustedSpacing))

        guard maxCount > prevCount else {return}
        // draw lines with indexes contained within the given rect
        // +1 is added because lines at the beggining of the next tile will be cut in half, so additional line at the end of the current (also cut in half) is added (this should be changed because it's probably problematic in certain cases)
        for i in prevCount..<(maxCount + 1)
        {
            var y: CGFloat = CGFloat(i) * adjustedSpacing + globalSpacing
            let relativeY: CGFloat = originRelativeY(for: y, globalSpacing: isEndCase ? layoutProperties.remaindersOnEachEnd.bottom : layoutProperties.remaindersOnEachEnd.top)

            // get appropriate attributes for the current line index
            var attributes: LineAttributes?
            if relativeY == 0 { attributes = horintalAxisAttributes }
            if attributes == nil { attributes = horizontalLineAttributes.first(where: {relativeY.truncatingRemainder(dividingBy: CGFloat($0.divisor)) == 0}) }
            
            // determine line width
            let lineWidth: CGFloat = attributes?.lineWidth ?? self.lineWidth

            // TODO: Maybe change this
            y += lineWidth > 1 ? 0 : (adjustedLineWidth / 2)
            // TODO: important for "end" cases
            print("y: \(y)")

            
            // TODO: if line width too big can be rendered outside
            y -= isEndCase ? .leastNormalMagnitude : 0
            
            print("y: \(y), relativeY: \(relativeY), lw: \(lineWidth)")

            // actually draw the line
            context.move(to: CGPoint(x:  rect.origin.x, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
            
            context.setStrokeColor((attributes?.color ?? lineColor).cgColor)
            context.setLineDash(phase: 0, lengths: attributes?.dashes.map({$0 / zoomScale}) ?? [])
            context.setLineWidth(lineWidth / zoomScale)
            context.strokePath()

            // draw text on the origin axis
            if relativeY == 0
            {
                let font: UIFont = UIFont.systemFont(ofSize: 14 / zoomScale)
                let string: NSAttributedString = NSAttributedString(string: originRelativeX(for: rect.maxX, globalSpacing: 0).description, attributes: [.font : font])
                let size: CGSize = string.size()
                string.draw(in: CGRect(x: rect.maxX - size.width, y: rect.midY, width: size.width, height: size.height))
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
        
        drawRandomSquares(rect, context: context)
        drawGrid(rect, context: context)
    }

    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Private -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    private func originRelativeX(for absoulteX: CGFloat, globalSpacing: CGFloat) -> CGFloat
    {
        let correction: CGFloat
        switch originPlacement
        {
        case .bottomRight, .centerRight, .topRight: correction = globalSpacing
        case .bottomLeft, .centerLeft, .topLeft: correction = -globalSpacing
        default: correction = 0
        }
        return (absoulteX + correction - originPlacement.origin(in: layoutProperties.lastReportedBounds).x) / scale
    }
    
//    private func originRelativeX(for absoluteLineIndex: UInt, globalSpacing: CGFloat) -> CGFloat
//    {
//        let relativeLineIndex: Int
//        let lastAbsoluteIndex: UInt = layoutProperties.verticalLineCount - 1
//        switch originPlacement
//        {
//        case .center, .topCenter, .bottomCenter:
//        default:
//            <#code#>
//        }
//        return 0
//    }

    private func originRelativeY(for absoluteY: CGFloat, globalSpacing: CGFloat) -> CGFloat
    {
        let correction: CGFloat
        switch originPlacement
        {
        case .topLeft, .topCenter, .topRight: correction = -globalSpacing
        case .bottomLeft, .bottomRight, .bottomCenter: correction = globalSpacing
        default: correction = 0
        }
        return (absoluteY + correction - originPlacement.origin(in: layoutProperties.lastReportedBounds).y) / scale
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
        layoutProperties.calculateLayoutProperties(lastReportedBounds: bounds, tileSideLength: sideLength, pointsPerLine: pixelsPerLine, originPlacement: originPlacement)
    }
}
