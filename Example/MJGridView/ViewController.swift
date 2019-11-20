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
    @IBOutlet weak var gridView: ZoomableGridView!
    
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
        
        gridView.backgroundColor = UIColor(red: 73/255, green: 72/255, blue: 80/255, alpha: 1)

        gridView.gridProperties.lineColor = UIColor(red: 229/255, green: 252/255, blue: 255/255, alpha: 1)
        gridView.gridProperties.horizontalLineAttributes = [LineAttributes(color: UIColor(red: 222/255, green: 26/255, blue: 26/255, alpha: 1), divisor: 3, dashes: [36, 36], lineWidth: 5, roundedCap: true)]
        gridView.gridProperties.horizontalAxisAttributes = LineAttributes(color: UIColor(red: 172/255, green: 172/255, blue: 222/255, alpha: 1), divisor: 0, dashes: [30, 55, 30, 30], lineWidth: 10, roundedCap: true)
        gridView.gridProperties.verticalLineAttributes = [LineAttributes(color: UIColor(red: 171/255, green: 218/255, blue: 252/255, alpha: 1), divisor: 3, dashes: [], lineWidth: 1, roundedCap: false)]
        gridView.gridProperties.verticalAxisAttributes = LineAttributes(color: UIColor(red: 172/255, green: 172/255, blue: 222/255, alpha: 1), divisor: 0, dashes: [], lineWidth: 2, roundedCap: false)
    }

    
    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Actions -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    @IBAction func spacingChanged(slider: UISlider!)
    {
        let value: UInt = UInt(slider.value)
        guard value != gridView.gridProperties.pixelsPerLine else {return}
        
        gridView.gridProperties.pixelsPerLine = UInt(slider.value)
        spacingLabel.text = "Spacing: \(gridView.gridProperties.pixelsPerLine)"
    }

    @IBAction func originPlacementChanged(slider: UISlider!)
    {
        let index: Int = Int(slider.value) % OriginPlacement.allCases.count
        guard index != OriginPlacement.allCases.lastIndex(of: gridView.gridProperties.originPlacement) else
        {
            placementLabel.text = "Placement: \(String.placementIcons.components(separatedBy: " ")[index])"
            return
        }
        
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
    
    @IBAction func redrawButtonTapped(button: UIButton!)
    {
        gridView.gridView.setNeedsDisplay()
    }
}

