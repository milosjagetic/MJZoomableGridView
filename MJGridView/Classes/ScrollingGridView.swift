//
//  ScrollingGridView.swift
//  MJGridView
//
//  Created by Milos Jagetic on 08/09/2019.
//

open class ScrollingGridView: UIView
{
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Public properties -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    open weak var gridView: TilingGridView!
    open weak var scrollView: UIScrollView!
    
    
    
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
        scrollView.delegate = self
        
        addSubview(scrollView)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|", options: [], metrics: nil, views: ["scrollView" : scrollView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView]|", options: [], metrics: nil, views: ["scrollView" : scrollView]))
        self.scrollView = scrollView

        let gridView: TilingGridView = TilingGridView(frame: bounds)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(gridView)
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[gridView]|", options: [], metrics: nil, views: ["gridView" : gridView]))
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[gridView]|", options: [], metrics: nil, views: ["gridView" : gridView]))
        scrollView.heightAnchor.constraint(equalTo: gridView.heightAnchor, multiplier: 0).isActive = true
        scrollView.widthAnchor.constraint(equalTo: gridView.widthAnchor, multiplier: 0).isActive = true
        
        self.gridView = gridView
    }
}


//  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
//  MARK: UIScrollViewDelegate protocol implementation -
//  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
extension ScrollingGridView: UIScrollViewDelegate
{
    public func viewForZooming(in scrollView: UIScrollView) -> UIView?
    {
        return gridView
    }
}

