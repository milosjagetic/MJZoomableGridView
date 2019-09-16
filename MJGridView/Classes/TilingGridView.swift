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
    open var verticalAxisAttributes: LineAttributes? = LineAttributes(color: .brown, divisor: 0, dashes: [], lineWidth: 10)
    
    open var originPlacement: OriginPlacement = .topRight { didSet { setNeedsDisplay() } }
    
    open var pixelsPerLine: Int = 23
    open var linesPerTile: Int = 2
    open var sideLength: CGFloat = 46
    open var lineWidth: CGFloat = 1 / UIScreen.main.scale
    open var lineColor: UIColor = .black
    open var scale: CGFloat = 2
    
    open var lastReportedBounds: CGRect = .zero
    {
        didSet
        {
            remainderOnEachEnd.x = lastReportedBounds.width.truncatingRemainder(dividingBy: sideLength)
            remainderOnEachEnd.y = lastReportedBounds.height.truncatingRemainder(dividingBy: sideLength)
        }
    }

    open override class var layerClass: AnyClass
    {
        return NoFadeTiledLayer.self
    }
    

    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Private properties -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    private var remainderOnEachEnd: CGPoint = .zero
    private var lastReportedTileFrame: CGRect = .zero

    
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
        ///This exists because "last" CGRects on the far end of x and y axis are almos always smaller than regular tile size. Relying on scrollViews.zoomScale results in bad behaviour when zoomin, due to multithreded nature of this drawing process
        struct SaneData
        {
            static var zoomScale: CGFloat = 0
        }
        
        if lastReportedTileFrame.size != rect.size && rect.maxX < lastReportedBounds.maxX && rect.maxY < lastReportedBounds.maxY
        {
            lastReportedTileFrame = rect
        }
        
        let zoomScale: CGFloat = context.ctm.a / UIScreen.main.scale
        let adjustedLineWidth: CGFloat =  lineWidth / zoomScale
        let adjustedSpacing: CGFloat = CGFloat(pixelsPerLine) / zoomScale
        
        context.setLineWidth(adjustedLineWidth)
        
        drawVerticalLines(in: rect, adjustedSpacing: adjustedSpacing, context: context)
        drawHorizontalLines(in: rect, adjustedSpacing: adjustedSpacing, context: context)
    }
    
    open func drawVerticalLines(in rect: CGRect, adjustedSpacing: CGFloat, context: CGContext)
    {
        let zoomScale: CGFloat = context.ctm.a / UIScreen.main.scale
        
        let globalSpacing: CGFloat = remainderOnEachEnd.x / 2
//        switch originPlacement
//        {
//        case .topCenter, .bottomCenter, .center: globalSpacing = remainderOnEachEnd.x / 2
//        case .centerRight, .topRight, .bottomRight: globalSpacing = -remainderOnEachEnd.x / 2
//        default: globalSpacing = 0
//        }
        
        let maxCount: Int = Int(ceil((rect.maxX - globalSpacing) / adjustedSpacing))
        let prevCount: Int = Int(ceil((rect.maxX - rect.width - globalSpacing) / adjustedSpacing))
        
        guard maxCount > prevCount else {return}
        
        for i in prevCount..<(maxCount + 1)
        {
            var x: CGFloat = CGFloat(i) * adjustedSpacing + globalSpacing
            
            let relativeX: CGFloat = originRelativeX(for: x, globalSpacing: globalSpacing)

            var attributes: LineAttributes?
            if relativeX == 0 { attributes = verticalAxisAttributes }
            if attributes == nil { attributes = verticalLineAttributes.first(where: {relativeX.truncatingRemainder(dividingBy: CGFloat($0.divisor)) == 0}) }

            let lineWidth: CGFloat = attributes?.lineWidth ?? self.lineWidth
            x += lineWidth > 1 ? 0 : ((lineWidth / zoomScale) / 2)

            context.move(to: CGPoint(x:  x, y: rect.origin.y))
            context.addLine(to: CGPoint(x: x, y: rect.maxY))
            
            
            context.setStrokeColor((attributes?.color ?? lineColor).cgColor)
            context.setLineDash(phase: 0, lengths: attributes?.dashes.map({$0 / zoomScale}) ?? [])
            context.setLineWidth(lineWidth / zoomScale)
            
            context.strokePath()
        }
    }
    
    open func drawHorizontalLines(in rect: CGRect, adjustedSpacing: CGFloat, context: CGContext)
    {
        let zoomScale: CGFloat = context.ctm.a / UIScreen.main.scale
        
        let globalSpacing: CGFloat = remainderOnEachEnd.y / 2
        let maxCount: Int = Int(ceil((rect.maxY - globalSpacing) / adjustedSpacing))
        let prevCount: Int = Int(ceil((rect.maxY - rect.height - globalSpacing) / adjustedSpacing))
        
        guard maxCount > prevCount else {return}
        //+1 is added because lines at the beggining of the next tile will be cut in half, so additional line at the end of the current (also cut in half) is added (this should be changed because it's probably problematic in certain cases)
        for i in prevCount..<(maxCount + 1)
        {
            var y: CGFloat = CGFloat(i) * adjustedSpacing + globalSpacing
            let relativeY: CGFloat = originRelativeY(for: y, globalSpacing: globalSpacing)
            
            if relativeY == 0
            {
                
            }
            var attributes: LineAttributes?
            if relativeY == 0 { attributes = horintalAxisAttributes }
            if attributes == nil { attributes = horizontalLineAttributes.first(where: {relativeY.truncatingRemainder(dividingBy: CGFloat($0.divisor)) == 0}) }
            
            let lineWidth: CGFloat = attributes?.lineWidth ?? self.lineWidth
            y += lineWidth > 1 ? 0 : ((lineWidth / zoomScale) / 2) // this solution is "accurate"
//            y += globalSpacing + ((lineWidth / zoomScale) / 2) // this solution fixes every other width being half width
            //though it has been fixed by adding a 'half' line in the preceeding tile
            
            context.move(to: CGPoint(x:  rect.origin.x, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
            
            context.setStrokeColor((attributes?.color ?? lineColor).cgColor)
            context.setLineDash(phase: 0, lengths: attributes?.dashes.map({$0 / zoomScale}) ?? [])
            context.setLineWidth(lineWidth / zoomScale)
            context.strokePath()
//
//
//            if relativeY == 0
//            {
//                let font: UIFont = UIFont.systemFont(ofSize: 20 / zoomScale)
//                let string: NSAttributedString = NSAttributedString(string: Int(originRelativeX(for: rect.maxX)).description, attributes: [.font : font])
//                let size: CGSize = string.size()
//                string.draw(in: CGRect(x: rect.maxX - size.width, y: rect.midY, width: size.width, height: size.height))
//            }
        }
    }

    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Overriden -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    open override func layoutSubviews()
    {
        super.layoutSubviews()
        lastReportedBounds = bounds
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
        return (absoulteX + correction - originPlacement.origin(in: lastReportedBounds).x) / scale
    }
    
    private func originRelativeY(for absoluteY: CGFloat, globalSpacing: CGFloat) -> CGFloat
    {
        let correction: CGFloat
        switch originPlacement
        {
        case .topLeft, .topCenter, .topRight: correction = -globalSpacing
        case .bottomLeft, .bottomRight, .bottomCenter: correction = globalSpacing
        default: correction = 0
        }
        return (absoluteY + correction - originPlacement.origin(in: lastReportedBounds).y) / scale
    }
    
    ///Draws a grid of randomly colored squares. Corresponds to placement of tiles. For debug purposes only
    private func drawRandomSquares(_ rect: CGRect, context: CGContext)
    {
        var rect: CGRect = rect
        rect.origin.x = rect.origin.x > bounds.width ? 0 : rect.origin.x
        rect.origin.y = rect.origin.y > bounds.height ? 0 : rect.origin.y
        context.setFillColor(UIColor.randomOpaque.withAlphaComponent(0.3).cgColor)
        context.fill(rect)
    }
}
