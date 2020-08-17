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
    private var gestureVisualizer: GestureVisualizer?
    private var genericGestureRecognizer: GenericGestureRecognizer?

    override func viewDidLoad() {
        super.viewDidLoad()
        genericGestureRecognizer = GenericGestureRecognizer(target: view)

        if let genericGestureRecognizer = genericGestureRecognizer {
            view.addGestureRecognizer(genericGestureRecognizer)

            genericGestureRecognizer.measurementsDidChange = { (measurement: GestureMeasurement) in
                print(measurement, measurement.data)
            }

            genericGestureRecognizer.gestureEnded = { () in
                self.gestureVisualizer?.draw(line: genericGestureRecognizer.gesturePath)
            }
        }
    }

    override func viewDidAppear(_: Bool) {
        if let window = UIApplication.shared.windows.last, gestureVisualizer == nil {
            gestureVisualizer = GestureVisualizer(frame: window.bounds)

            if let gestureVisualizer = gestureVisualizer {
                window.addSubview(gestureVisualizer)
                gestureVisualizer.topAnchor.constraint(equalTo: window.topAnchor).isActive = true
                gestureVisualizer.bottomAnchor.constraint(equalTo: window.bottomAnchor).isActive = true
                gestureVisualizer.leadingAnchor.constraint(equalTo: window.leadingAnchor).isActive = true
                gestureVisualizer.trailingAnchor.constraint(equalTo: window.trailingAnchor).isActive = true
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
