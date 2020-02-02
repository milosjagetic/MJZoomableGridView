//
//  ScrollingGridView.swift
//  MJGridView
//
//  Created by Milos Jagetic on 08/09/2019.
//

open class ZoomableGridView: UIView
{
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Public properties -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    open weak var gridView: TilingGridView!
    open weak var scrollView: UIScrollView!
    
    open var gridProperties: GridProperties = .init() {didSet {gridView.gridProperties = gridProperties}}
    
    @IBInspectable open var maximumZoomScale: CGFloat = 1
    {
        didSet
        {
            scrollView.maximumZoomScale = maximumZoomScale
            gridView.updateLevelsOfDetail(minZoom: minimumZoomScale, maxZoom: maximumZoomScale)
        }
    }
    
    @IBInspectable open var minimumZoomScale: CGFloat = 1
    {
        didSet
        {
            scrollView.removeConstraint(gridWidth)
            scrollView.removeConstraint(gridHeight)
            
            gridHeight = scrollView.heightAnchor.constraint(equalTo: gridView.heightAnchor, multiplier: minimumZoomScale)
            gridHeight.isActive = true
            
            gridWidth = scrollView.widthAnchor.constraint(equalTo: gridView.widthAnchor, multiplier: minimumZoomScale)
            gridWidth.isActive = true

            scrollView.minimumZoomScale = minimumZoomScale
            gridView.updateLevelsOfDetail(minZoom: minimumZoomScale, maxZoom: maximumZoomScale)
            
        }
    }
    
    private var gridHeight: NSLayoutConstraint!
    private var gridWidth: NSLayoutConstraint!

    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Lifecycle -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    public override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        myInit()
    }
    
    
    public required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        myInit()
    }
    
    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Private -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    private func myInit()
    {
        let scrollView: UIScrollView = UIScrollView(frame: bounds)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.delegate = self
        
        addSubview(scrollView)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|", options: [], metrics: nil, views: ["scrollView" : scrollView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView]|", options: [], metrics: nil, views: ["scrollView" : scrollView]))
        self.scrollView = scrollView

        let gridView: TilingGridView = TilingGridView(frame: bounds)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.backgroundColor = .clear
        
        scrollView.addSubview(gridView)
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[gridView]|", options: [], metrics: nil, views: ["gridView" : gridView]))
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[gridView]|", options: [], metrics: nil, views: ["gridView" : gridView]))
        gridHeight = scrollView.heightAnchor.constraint(equalTo: gridView.heightAnchor, multiplier: 1 / minimumZoomScale)
        gridHeight.isActive = true
        
        gridWidth = scrollView.widthAnchor.constraint(equalTo: gridView.widthAnchor, multiplier: 1 / minimumZoomScale)
        gridWidth.isActive = true
        
        self.gridView = gridView
    }
}


//  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
//  MARK: UIScrollViewDelegate protocol implementation -
//  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
extension ZoomableGridView: UIScrollViewDelegate
{
    public func viewForZooming(in scrollView: UIScrollView) -> UIView?
    {
        return gridView
    }
}

