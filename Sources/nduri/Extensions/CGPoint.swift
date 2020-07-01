//
//  Stopwatch.swift
//
//  Created by Moritz Herbert on 01.07.20.
//

import CoreGraphics

extension CGPoint {
    func slope(to: CGPoint) -> CGFloat {
        let distanceX = to.x - x
        let distanceY = to.y - y

        return distanceY / distanceX
    }

    func distanceTo(lineSegmentBetween l1: CGPoint, and l2: CGPoint) -> CGFloat {
        let a = x - l1.x
        let b = y - l1.y
        let c = l2.x - l1.x
        let d = l2.y - l1.y

        let dot = a * c + b * d
        let lengthSquared = c * c + d * d
        var param = CGFloat(-1)
        if !lengthSquared.isZero { // in case of 0 length line
            param = dot / lengthSquared
        }

        var xx: CGFloat
        var yy: CGFloat

        if param < 0 || (l1.x == l2.x && l1.y == l2.y) {
            xx = l1.x
            yy = l1.y
        } else if param > 1 {
            xx = l2.x
            yy = l2.y
        } else {
            xx = l1.x + param * c
            yy = l1.y + param * d
        }

        let dx = x - xx
        let dy = y - yy

        return (dx * dx + dy * dy).squareRoot()
    }

    func distance(to point: CGPoint) -> CGFloat {
        sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
