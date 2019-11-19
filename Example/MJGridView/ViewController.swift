//
//  ViewController.swift
//  MJGridView
//
//  Created by Miloš Jagetić on 09/05/2019.
//  Copyright (c) 2019 Miloš Jagetić. All rights reserved.
//

import UIKit
import MJGridView

private extension String
{
    static let placementIcons: String = "╋ ┳ ┓ ┫ ┛ ┻ ┖ ┣ ┏"
}

class ViewController: UIViewController
{
    @IBOutlet weak var gridView: ScrollingGridView!
    
    @IBOutlet weak var spacingLabel: UILabel!
    @IBOutlet weak var placementLabel: UILabel!
    @IBOutlet weak var spacingSlider: UISlider!
    @IBOutlet weak var placementSlider: UISlider!
    @IBOutlet weak var toolboxHidden: NSLayoutConstraint!

    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        spacingSlider.minimumValue = 25
        spacingSlider.maximumValue = 300
        spacingSlider.value = 25
        
        placementSlider.minimumValue = 0
        placementSlider.maximumValue = Float(OriginPlacement.allCases.count - 1)
        placementSlider.value = 0
        
        spacingChanged(slider: spacingSlider)
        originPlacementChanged(slider: placementSlider)

        gridView.gridProperties.lineColor = UIColor(red: 85/255, green: 83/255, blue: 88/255, alpha: 1)
        gridView.gridProperties.horizontalLineAttributes = [LineAttributes(color: .red, divisor: 3, dashes: [36, 36], lineWidth: 5, roundedCap: true)]
        gridView.gridProperties.horizontalAxisAttributes = LineAttributes(color: UIColor(red: 237/255, green: 37/255, blue: 78/255, alpha: 1), divisor: 0, dashes: [221, 36, 0, 36], lineWidth: 10, roundedCap: true)
        gridView.gridProperties.verticalLineAttributes = [LineAttributes(color: .blue, divisor: 3, dashes: [], lineWidth: 1, roundedCap: false)]
        gridView.gridProperties.verticalAxisAttributes = LineAttributes(color: UIColor(red: 249/255, green: 220/255, blue: 92/255, alpha: 1), divisor: 0, dashes: [], lineWidth: 10, roundedCap: false)
    }

    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Actions -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    @IBAction func spacingChanged(slider: UISlider!)
    {
        gridView.gridProperties.pixelsPerLine = UInt(slider.value)
        spacingLabel.text = "Spacing: \(gridView.gridProperties.pixelsPerLine)"
    }

    @IBAction func originPlacementChanged(slider: UISlider!)
    {
        let index: Int = Int(slider.value) % OriginPlacement.allCases.count
        guard index != OriginPlacement.allCases.lastIndex(of: gridView.gridProperties.originPlacement) else {return}
        
        gridView.gridProperties.originPlacement = OriginPlacement.allCases[index]
        placementLabel.text = "Placement: \(String.placementIcons.components(separatedBy: " ")[index])"
    }
    
    @IBAction func toolboxButtonTapped(button: UIButton!)
    {
        button.isSelected = !button.isSelected
        toolboxHidden.priority = button.isSelected ? .defaultLow : .defaultHigh
        UIView.animate(withDuration: 1/4, delay: 0, usingSpringWithDamping: 4/5, initialSpringVelocity: 1, options: [], animations:
        {
            self.view.layoutIfNeeded()
        })
    }
}

