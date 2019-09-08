//
//  OriginPlacement.swift
//  GridSnap
//
//  Created by Milos Jagetic on 02/09/2019.
//  Copyright © 2019 Milos Jagetic. All rights reserved.
//

import UIKit

public enum OriginPlacement
{
    case center
    case topCenter
    case topRight
    case centerRight
    case bottomRight
    case bottomCenter
    case bottomLeft
    case centerLeft
    case topLeft
    case custom(CGFloat, CGFloat)
    
    func origin(in: CGRect) -> CGPoint
    {
        return .zero	
    }
}
