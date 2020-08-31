//
//  Nduri.swift
//
//
//  Created by Moritz Herbert on 25.08.20.
//

import UIKit

@available(iOS 10.0, *)
public final class Nduri: NSObject {
    enum SystemPhase {
        case enrolment
        case verification
    }

    public static let shared = Nduri()

    public private(set) var genericGestureRecognizer: GenericGestureRecognizer?
    public private(set) var measurementsLog = MeasurementsList()
    private var gestureVisualizer: GestureVisualizer?
    private var phase: SystemPhase = .enrolment

    public var measurementsDidChange: ((GestureMeasurement) -> Void)? {
        didSet {
            measurementsLog.listDidChange = measurementsDidChange
        }
    }

    public func setup(in view: UIView) {
        genericGestureRecognizer = GenericGestureRecognizer(target: view)
        genericGestureRecognizer?.cancelsTouchesInView = false

        genericGestureRecognizer?.measurementCreated = { [unowned self] measurement in
            switch self.phase {
            case .enrolment:
                self.measurementsLog.append(measurement)
            case .verification: ()
            }
        }

        genericGestureRecognizer?.gestureEnded = { [unowned self] () in
            self.gestureVisualizer?.draw(line: self.genericGestureRecognizer?.gesturePath ?? [])
        }

        enroll()
    }

    public func enroll() {
        measurementsLog = MeasurementsList()

        phase = .enrolment

        Timer.scheduledTimer(withTimeInterval: 60 * 60 * 4, repeats: false) { _ in // TODO: adjust interval. 10-15 minutes?!
            self.phase = .verification
        }
    }

    public func addVisualizationTo(window: UIWindow) {
        if gestureVisualizer == nil {
            gestureVisualizer = GestureVisualizer(window: window)
        }
    }

    public func removeVisualization() {
        gestureVisualizer = nil
    }
}

