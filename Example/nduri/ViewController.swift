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
    override func viewDidLoad() {
        super.viewDidLoad()

        Nduri.shared.setup(in: view)

        if let genericGestureRecognizer = Nduri.shared.genericGestureRecognizer {
            view.addGestureRecognizer(genericGestureRecognizer)

            Nduri.shared.measurementsDidChange = { (measurement: GestureMeasurement) in
                print(measurement, measurement.data)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let window = UIApplication.shared.windows.last {
            Nduri.shared.addVisualizationTo(window: window)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if let window = UIApplication.shared.windows.last {
            Nduri.shared.removeVisualization()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
