//
//  GestureVisualizer.swift
//
//  Created by Moritz Herbert on 31.03.20.
//

import UIKit

@available(iOS 9.0, *)
public final class GestureVisualizer: UIView {
    private var line: [CGPoint]?

    public init(window: UIWindow) {
        super.init(frame: window.frame)

        window.addSubview(self)
        topAnchor.constraint(equalTo: window.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: window.bottomAnchor).isActive = true
        leadingAnchor.constraint(equalTo: window.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: window.trailingAnchor).isActive = true

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
        context?.setStrokeColor(UIColor.blue.cgColor)

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
