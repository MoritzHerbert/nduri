//
//  ViewController.swift
//  nduri
//
//  Created by Moritz Herbert on 04/22/2020.
//  Copyright (c) 2020 Moritz Herbert. All rights reserved.
//

import nduri
import UIKit

class ViewController: UIViewController {
    private var heatmap: Heatmap?
    private var genericGestureRecognizer: GenericGestureRecognizer?

    override func viewDidLoad() {
        super.viewDidLoad()
        genericGestureRecognizer = GenericGestureRecognizer(target: view)

        if let genericGestureRecognizer = genericGestureRecognizer {
            view.addGestureRecognizer(genericGestureRecognizer)

            genericGestureRecognizer.measurementsDidChange = { (_: GestureMeasurement) in
                print("JSON log: \(String(data: genericGestureRecognizer.measurementsLog.jsonLog!, encoding: .utf8))")
            }

            genericGestureRecognizer.fingerDidMove = { (start: CGPoint, end: CGPoint) in
                self.heatmap?.drawLine(from: start, to: end)
            }
        }
    }

    override func viewDidAppear(_: Bool) {
        if let window = UIApplication.shared.keyWindow, heatmap == nil {
            heatmap = Heatmap(frame: window.bounds)

            if let heatmap = heatmap {
                window.addSubview(heatmap)
            }

            heatmap?.topAnchor.constraint(equalTo: window.topAnchor).isActive = true
            heatmap?.bottomAnchor.constraint(equalTo: window.bottomAnchor).isActive = true
            heatmap?.leadingAnchor.constraint(equalTo: window.leadingAnchor).isActive = true
            heatmap?.trailingAnchor.constraint(equalTo: window.trailingAnchor).isActive = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
