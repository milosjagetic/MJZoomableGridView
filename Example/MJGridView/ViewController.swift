//
//  ViewController.swift
//  MJGridView
//
//  Created by Miloš Jagetić on 09/05/2019.
//  Copyright (c) 2019 Miloš Jagetić. All rights reserved.
//

import UIKit
import MJGridView

class ViewController: UIViewController
{
    @IBOutlet weak var gridView: ScrollingGridView!
    
    
    @IBAction func stepperChanged(_ stepper: UIStepper!)
    {
        let placements: [OriginPlacement] = [.center, .topCenter, .topRight, .centerRight, .bottomRight, .bottomCenter, .bottomLeft, .centerLeft, .topLeft]
        gridView.gridView.originPlacement = placements[Int(stepper.value) % placements.count]
    }


}

