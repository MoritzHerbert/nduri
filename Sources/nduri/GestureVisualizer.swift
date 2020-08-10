//
//  GestureVisualizer.swift
//
//  Created by Moritz Herbert on 31.03.20.
//

import UIKit

public final class GestureVisualizer: UIView {
    private var line: [CGPoint]?

    override public init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        isUserInteractionEnabled = false
    }

    override public func draw(_ rect: CGRect) {
        guard let line = line, line.count > 1 else { return }

        let context = UIGraphicsGetCurrentContext()
        context?.clear(rect)
        context?.beginPath()
        context?.setLineWidth(4.0)
        context?.setStrokeColor(UIColor.orange.cgColor)

        context?.move(to: line.first!)

        for i in 1 ..< line.count {
            context?.addLine(to: line[i])
        }

        context?.strokePath()
        context?.setLineWidth(2.0)
        context?.setStrokeColor(UIColor.green.cgColor)

        context?.move(to: line.first!)
        context?.addLine(to: line.last!)

        let dashes: [CGFloat] = [8, 8]
        context?.setLineDash(phase: 0.0, lengths: dashes)
        context?.strokePath()
    }

    public func draw(line: [CGPoint]) {
        self.line = line
        setNeedsDisplay()
    }
}
