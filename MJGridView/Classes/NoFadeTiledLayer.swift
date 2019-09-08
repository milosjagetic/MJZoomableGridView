//
//  MJTiledLayer.swift
//  MJGridView
//
//  Created by Milos Jagetic on 08/09/2019.
//

import Foundation

internal class NoFadeTiledLayer: CATiledLayer
{
    override class func fadeDuration() -> CFTimeInterval
    {
        return 0
    }
}
