//
//  GenericGestureRecognizer.swift
//
//  Created by Moritz Herbert on 31.03.20.
//

import Foundation
import CoreMotion

// indicate deflection when e.g. scrolling
enum StrokePhases: String {
    case notStarted
    case initialPoint
    case moved
}

public enum StrokeDeflection: String {
    case eastStroke
    case southeastStroke
    case southStroke
    case southwestStroke
    case westStroke
    case northwestStroke
    case northStroke
    case northeastStroke
}

// indicate where strokes took plase (should be used relative to scrollable areas)
enum Grid {
    case veryTopLeft
    case veryTopRight
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case veryBottomLeft
    case veryBottomRight
}

public class GestureMeasurement {
    public var data: Any?

    init(data: Any?) {
        self.data = data
    }
}

public class Force: GestureMeasurement {
    init(data: CGFloat) {
        super.init(data: data)
    }
}

public class Deflection: GestureMeasurement {
    init(data: StrokeDeflection) {
        super.init(data: data)
    }
}

public class Tilt: GestureMeasurement {
    init(data: Double) {
        super.init(data: data)
    }
}

public class MeasurementsList {
    private var measurements: [GestureMeasurement] = []

    public var listDidChange: ((GestureMeasurement) -> ())?

//    subscript(actionIndex:Int) -> GestureMeasurement {
//        get {
//            return measurements[actionIndex]
//        }
//        set {
//            measurements[actionIndex] = newValue
//            if let listDidChange = listDidChange {
//                listDidChange(newValue)
//            }
//        }
//    }

    func append(_ measurement: GestureMeasurement) {
        measurements.append(measurement)
        listDidChange?(measurement)
    }
}

public class GenericGestureRecognizer: UIGestureRecognizer {
    private var strokePhase: StrokePhases = .notStarted
    private var initialTouchPoint = CGPoint.zero
    private var trackedTouch: UITouch? = nil
    private(set) var measurementsLog = MeasurementsList()
    private var motionManager: CMMotionManager!
    private var motionTimer: Timer?

    public var measurementsDidChange: ((GestureMeasurement) -> ())? {
        didSet {
            measurementsLog.listDidChange = measurementsDidChange
        }
    }

    public var fingerDidMove: ((CGPoint, CGPoint) -> ())?

    public init(target: Any?) {
        super.init(target: target, action: nil)

        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()

        #if !targetEnvironment(simulator)
        motionTimer = Timer.scheduledTimer(withTimeInterval: 1,
                                           repeats: false,
                                           block: { _ in

                                            if let accelerometerData = motionManager.accelerometerData {
                                                print(accelerometerData.acceleration.x)
                                            }
        })
        #endif
    }



    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        // let's not consider multitouch for now
        if touches.count != 1 {
            state = .failed
        }

        // Capture the first touch and store some information about it.
        if trackedTouch == nil {
            trackedTouch = touches.first
            strokePhase = .initialPoint
            initialTouchPoint = (trackedTouch?.location(in: view))!
        } else {
            // Ignore all but the first touch.
            for touch in touches {
                if touch != trackedTouch {
                    ignore(touch, for: event)
                }
            }
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        // There should be only the first touch.
        guard let newTouch = touches.first, newTouch == self.trackedTouch else {
            state = .failed
            return
        }

        if strokePhase == .initialPoint {
            // Make sure the initial movement is down and to the right.
            strokePhase = .moved


        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)

        guard let newTouch = touches.first, newTouch == self.trackedTouch else {
            state = .failed
            return
        }

        switch strokePhase {
        case .initialPoint:
            if #available(iOS 9.1, *), !newTouch.force.isZero {
                let force = newTouch.force
                let normalisedForce = force / newTouch.maximumPossibleForce

                measurementsLog.append(Force(data: normalisedForce.isNaN ? force : normalisedForce))
            } else {
                // Fallback on earlier versions
            }
        case .moved:
            let deflection = determineDeflection(from: initialTouchPoint, to: newTouch.location(in: view))
            measurementsLog.append(Deflection(data: deflection))
            fingerDidMove?(initialTouchPoint, newTouch.location(in: view))
        default: ()
        }

        state = .ended
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        self.initialTouchPoint = CGPoint.zero
        self.strokePhase = .notStarted
        self.trackedTouch = nil
        self.state = .cancelled
    }

    public override func reset() {
        super.reset()
        self.initialTouchPoint = CGPoint.zero
        self.strokePhase = .notStarted
        self.trackedTouch = nil
    }

    private func determineDeflection(from start: CGPoint, to end: CGPoint) -> StrokeDeflection { // TODO: Revisit slope numbers
        let slope = start.slope(to: end)

        if slope < -2 {
            return start.x <= end.x ? .northStroke : .southStroke
        } else if slope < -0.5 {
            return start.x <= end.x ? .northeastStroke : .southwestStroke
        } else if slope < 0.5 {
            return start.x <= end.x ? .eastStroke : .westStroke
        } else if slope < 2 {
            return start.x <= end.x ? .southeastStroke : .northwestStroke
        }

        return start.x <= end.x ? .southStroke : .northStroke
    }
}

// MARK: - Extensions

extension CGPoint {
    func slope(to: CGPoint) -> CGFloat{
        let distanceX = to.x - self.x
        let distanceY = to.y - self.y

        return distanceY / distanceX
    }

    func distanceTo(lineSegmentBetween l1: CGPoint, and l2: CGPoint) -> CGFloat {
        let a = self.x - l1.x
        let b = self.y - l1.y
        let c = l2.x - l1.x
        let d = l2.y - l1.y

        let dot = a * c + b * d
        let lengthSquared = c * c + d * d
        var param = CGFloat(-1)
        if (!lengthSquared.isZero) { //in case of 0 length line
            param = dot / lengthSquared
        }

        var xx: CGFloat
        var yy: CGFloat

        if (param < 0 || (l1.x == l2.x && l1.y == l2.y)) {
            xx = l1.x
            yy = l1.y
        } else if (param > 1) {
            xx = l2.x
            yy = l2.y
        } else {
            xx = l1.x + param * c
            yy = l1.y + param * d
        }

        let dx = self.x - xx
        let dy = self.y - yy

        return (dx * dx + dy * dy).squareRoot()
    }
}

extension CGFloat {
    var stringValue: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 3
        numberFormatter.maximumFractionDigits = 3

        return numberFormatter.string(from: NSNumber(nonretainedObject: self)) ?? ""
    }
}
