//
//  OriginPlacement.swift
//  GridSnap
//
//  Created by Milos Jagetic on 02/09/2019.
//  Copyright © 2019 Milos Jagetic. All rights reserved.
//

import UIKit

/// Placement of origin witihin the grid. Use `custom` for non trivial placements. `custom` placement's coordinates are relative to the ZoomableGridView's frame
public enum OriginPlacement: Equatable
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
    case custom(CGPoint)
    
    public func origin(in rect: CGRect) -> CGPoint
    {
        switch self
        {
        case .center: return CGPoint(x: rect.midX, y: rect.midY)
        case .topCenter: return CGPoint(x: rect.midX, y: 0)
        case .topRight: return CGPoint(x: rect.maxX, y: 0)
        case .centerRight: return CGPoint(x: rect.maxX, y: rect.midY)
        case .bottomRight: return CGPoint(x: rect.maxX, y: rect.maxY)
        case .bottomCenter: return CGPoint(x: rect.midX, y: rect.maxY)
        case .bottomLeft: return CGPoint(x: 0, y: rect.maxY)
        case .centerLeft: return CGPoint(x:0, y: rect.midY)
        case .topLeft: return CGPoint(x: 0, y: 0)
        case .custom(let point): return point
        }
    }

    //  //= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =\\
    //  MARK: Equatable protocol implementation -
    //  \\= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =//
    public static func ==(lhs: OriginPlacement, rhs: OriginPlacement) -> Bool
    {
        switch (lhs, rhs)
        {
        case (.center, .center): return true
        case (.topCenter, .topCenter): return true
        case (.topRight, .topRight): return true
        case (.centerRight, .centerRight): return true
        case (.bottomRight, .bottomRight): return true
        case (.bottomCenter, .bottomCenter): return true
        case (.bottomLeft, .bottomLeft): return true
        case (.centerLeft, .centerLeft): return true
        case (.topLeft, .topLeft): return true
        case (.custom(let lhs), .custom(let rhs)): return lhs == rhs
        default: return false
        }
    }
}
