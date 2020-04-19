//
//  DebugLevel.swift
//  MJGridView
//
//  Created by Milos Jagetic on 04/02/2020.
//

import Foundation

public enum DebugLevel: UInt
{
    /// Default debug level. No logging.
    case none = 0
    /// Prints out render timings
    case performanceAnalysis = 1
    /// Draws a randomly colored grid of squares corresponding to the actual grid
    case randomSquares = 2
}
