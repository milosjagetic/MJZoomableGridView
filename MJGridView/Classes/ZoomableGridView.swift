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
    open weak var gridContainerView: UIView!
    open weak var scrollView: UIScrollView!
    
    open var gridProperties: GridProperties = .init() {didSet {gridView.gridProperties = gridProperties}}
    
    open var debugLevel: DebugLevel = .none {didSet {gridView.debugLevel = debugLevel}}
    
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
    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Private properties -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
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
        //scroll
        let scrollView: UIScrollView = UIScrollView(frame: bounds)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.delegate = self
        if #available(iOS 11.0, *) { scrollView.contentInsetAdjustmentBehavior = .never }
        
        scrollView.pin(to: self)
        self.scrollView = scrollView
    
        //container
        let gridContainer: UIView = UIView()
        gridContainer.backgroundColor = .clear
        gridContainer.translatesAutoresizingMaskIntoConstraints = false
        
        gridContainer.pin(to: scrollView)
        self.gridContainerView = gridContainer
        gridHeight = scrollView.heightAnchor.constraint(equalTo: gridContainer.heightAnchor, multiplier: 1 / minimumZoomScale)
        gridHeight.isActive = true
        
        gridWidth = scrollView.widthAnchor.constraint(equalTo: gridContainer.widthAnchor, multiplier: 1 / minimumZoomScale)
        gridWidth.isActive = true

        //grid
        let gridView: TilingGridView = TilingGridView(frame: bounds)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.backgroundColor = .clear
        
        gridView.pin(to: gridContainer)
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
        return gridContainerView
    }
}


//  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
//  MARK: Helper -
//  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
private extension UIView
{
    func pin(to: UIView)
    {
        to.addSubview(self)
        to.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[me]|", options: [], metrics: nil, views: ["me" : self]))
        to.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[me]|", options: [], metrics: nil, views: ["me" : self]))
    }
}

