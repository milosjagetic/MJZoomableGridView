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
    open weak var gridView: MJTilingGridView!
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

        addSubview(scrollView)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|", options: [], metrics: nil, views: ["scrollView" : scrollView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView]|", options: [], metrics: nil, views: ["scrollView" : scrollView]))
        self.scrollView = scrollView

        let gridView: MJTilingGridView = MJTilingGridView(frame: bounds)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(gridView)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[gridView]|", options: [], metrics: nil, views: ["gridView" : gridView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[gridView]|", options: [], metrics: nil, views: ["gridView" : gridView]))
        
        self.gridView = gridView
    }
}

