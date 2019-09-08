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
    open var horizontalLineAttributes: [LineAttributes] = [LineAttributes(color: .red, divisor: 4, dashes: [10,10], lineWidth: 5), LineAttributes(color: .green, divisor: 2, dashes: [], lineWidth: 1)]
    
    open var verticalLineAttributes: [LineAttributes] = [LineAttributes(color: .blue, divisor: 3, dashes: [], lineWidth: 1)]
    
    open var originPlacement: OriginPlacement = .center
    
    open var pixelsPerLine: Int = 50
    open var linesPerTile: Int = 2
    open var sideLength: CGFloat = 100
    open var lineWidth: CGFloat = 1 / UIScreen.main.scale
    open var lineColor: UIColor = .black
    open var scale: CGFloat = 20
    
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
        let maxCount: Int = Int(ceil((rect.maxX - globalSpacing) / adjustedSpacing))
        let prevCount: Int = Int(ceil((rect.maxX - rect.width - globalSpacing) / adjustedSpacing))
        
        guard maxCount > prevCount else {return}
        
        for i in min(prevCount, (maxCount - prevCount))..<maxCount
        {
            var x: CGFloat = CGFloat(i) * adjustedSpacing
            let attributes: LineAttributes? = verticalLineAttributes.first(where: {(x / scale).truncatingRemainder(dividingBy: CGFloat($0.divisor)) == 0})
            if attributes != nil
            {
                
            }
            let lineWidth: CGFloat = attributes?.lineWidth ?? self.lineWidth
            x += globalSpacing + (lineWidth > 1 ? 0 : ((lineWidth / zoomScale) / 2))
            
            context.move(to: CGPoint(x:  x, y: rect.origin.y))
            context.addLine(to: CGPoint(x: x, y: rect.maxY))
            
            
            context.setStrokeColor((attributes?.color ?? lineColor).cgColor)
            context.setLineDash(phase: 0, lengths: attributes?.dashes.map({$0 / zoomScale}) ?? [])
            context.setLineWidth((attributes?.lineWidth ?? lineWidth) / zoomScale)
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
        
        for i in min(prevCount, (maxCount - prevCount))..<maxCount
        {
            var y: CGFloat = CGFloat(i) * adjustedSpacing
            let attributes: LineAttributes? = horizontalLineAttributes.first(where: {(y / scale).truncatingRemainder(dividingBy: CGFloat($0.divisor)) == 0})
            let lineWidth: CGFloat = attributes?.lineWidth ?? self.lineWidth
            y += globalSpacing + (lineWidth > 1 ? 0 : ((lineWidth / zoomScale) / 2))
            
            context.move(to: CGPoint(x:  rect.origin.x, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
            
            
            context.setStrokeColor((attributes?.color ?? lineColor).cgColor)
            context.setLineDash(phase: 0, lengths: attributes?.dashes.map({$0 / zoomScale}) ?? [])
            context.setLineWidth((attributes?.lineWidth ?? lineWidth) / zoomScale)
            context.strokePath()
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
        
        drawGrid(rect, context: context)
        //        drawRandomSquares(rect, context: context)
    }

    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Private -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    private func drawRandomSquares(_ rect: CGRect, context: CGContext)
    {
        var rect: CGRect = rect
        rect.origin.x = rect.origin.x > bounds.width ? 0 : rect.origin.x
        rect.origin.y = rect.origin.y > bounds.height ? 0 : rect.origin.y
        context.setFillColor(UIColor.randomOpaque.cgColor)
        context.fill(rect)
    }
}
