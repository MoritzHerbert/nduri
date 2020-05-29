//
//  Heatmap.swift
//
//  Created by Moritz Herbert on 31.03.20.
//

import UIKit

private struct Line {
    public let start: CGPoint
    public let end: CGPoint
}

public class Heatmap: UIView {
    private var lineToDraw: Line?

    override public init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        isUserInteractionEnabled = false
    }

    override public func draw(_ rect: CGRect) {
        guard let lineToDraw = lineToDraw else { return }

        let context = UIGraphicsGetCurrentContext()
        context?.clear(rect)
        context?.beginPath()
        context?.setLineWidth(4.0)
        context?.setStrokeColor(UIColor.orange.cgColor)

        context?.move(to: lineToDraw.start)
        context?.addLine(to: lineToDraw.end)

        context?.strokePath()

        self.lineToDraw = nil
    }

    public func drawLine(from start: CGPoint, to end: CGPoint) {
        lineToDraw = Line(start: start, end: end)

        setNeedsDisplay()
    }
}
