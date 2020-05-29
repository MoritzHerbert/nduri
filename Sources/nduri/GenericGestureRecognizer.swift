//
//  GenericGestureRecognizer.swift
//
//  Created by Moritz Herbert on 31.03.20.
//

import CoreMotion
import UIKit

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

public enum Direction: String {
    case left
    case right
    case none
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
    public var datetime: Date
    public var dataString: String {
        if let nonNil = data, !(nonNil is NSNull) {
            return String(describing: nonNil)
        }

        return ""
    }

    init(data: Any?) {
        self.data = data
        datetime = Date()
    }
}

public class Force: GestureMeasurement {
    init(data: Double) {
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

public class LinearStrokeDeviance: GestureMeasurement {
    init(data: Double) {
        super.init(data: data)
    }
}

public class LinearStrokeDevianceDirection: GestureMeasurement {
    init(data: Direction) {
        super.init(data: data)
    }
}

// points per milliseconds
public class StrokeSpeed: GestureMeasurement {
    init(data: Double) {
        super.init(data: data)
    }
}

// microseconds
public class TapDuration: GestureMeasurement {
    init(data: Double) {
        super.init(data: data)
    }
}

public struct LoggableMeasurement: Codable { // Cannot easily make data: Any from GestureMeasurement codable, therefore this intermediate struct is used for JSON parsing
    var event: String
    var data: String
    var datetime: Date
}

public class MeasurementsList {
    private var measurements: [GestureMeasurement] = []

    public var listDidChange: ((GestureMeasurement) -> Void)?
    public var jsonLog: Data? {
        let stringifiedMeasurements = measurements.map { LoggableMeasurement(event: String(describing: type(of: $0)), data: $0.dataString, datetime: $0.datetime) }

        let encoder = JSONEncoder()

        return try? encoder.encode(stringifiedMeasurements)
    }

    func append(_ measurement: GestureMeasurement) {
        measurements.append(measurement)
        listDidChange?(measurement)
    }
}

public class GenericGestureRecognizer: UIGestureRecognizer {
    private var strokePhase: StrokePhases = .notStarted
    private var initialTouchPoint = CGPoint.zero
    private var trackedTouch: UITouch?
    public private(set) var measurementsLog = MeasurementsList()
    private var motionManager: CMMotionManager!
    private var motionTimer: Timer?
    private var gesturePath: [CGPoint]!
    private var strokeStopwatch = Stopwatch()
    private var tapStopwatch = Stopwatch()

    public var measurementsDidChange: ((GestureMeasurement) -> Void)? {
        didSet {
            measurementsLog.listDidChange = measurementsDidChange
        }
    }

    public var fingerDidMove: ((CGPoint, CGPoint) -> Void)?

    public init(target: Any?) {
        super.init(target: target, action: nil)

        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()

        gesturePath = []

        #if !targetEnvironment(simulator)
            motionTimer = Timer.scheduledTimer(withTimeInterval: 5,
                                               repeats: true,
                                               block: { _ in

                                                   if let accelerometerData = motionManager.accelerometerData {
                                                       print(accelerometerData.acceleration.x)
                                                   }
        })
        #endif
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        tapStopwatch.start()
        strokeStopwatch.start()

        // let's not consider multitouch for now
        if touches.count != 1 {
            state = .failed
        }

        // Capture the first touch and store some information about it.
        if trackedTouch == nil {
            trackedTouch = touches.first
            strokePhase = .initialPoint
            initialTouchPoint = (trackedTouch?.location(in: view))!
            gesturePath.append(initialTouchPoint)
        } else {
            // Ignore all but the first touch.
            for touch in touches {
                if touch != trackedTouch {
                    ignore(touch, for: event)
                }
            }
        }
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        // There should be only the first touch.
        guard let newTouch = touches.first, newTouch == trackedTouch else {
            state = .failed
            return
        }

        if strokePhase == .initialPoint {
            // Make sure the initial movement is down and to the right.
            strokePhase = .moved
        }

        gesturePath.append(newTouch.location(in: view))
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        _ = tapStopwatch.stop()
        let strokeDuration = strokeStopwatch.stop()

        guard let newTouch = touches.first, newTouch == trackedTouch else {
            state = .failed
            return
        }

        let endPoint = newTouch.location(in: view)

        switch strokePhase {
        case .initialPoint:
            if #available(iOS 9.1, *), !newTouch.force.isZero {
                let force = newTouch.force
                let normalisedForce = force / newTouch.maximumPossibleForce

                measurementsLog.append(Force(data: Double(normalisedForce.isNaN ? force : normalisedForce)))
            } else {
                // Fallback on earlier versions
            }

            if let tapDuration = tapStopwatch.microseconds {
                measurementsLog.append(TapDuration(data: tapDuration))
            }
        case .moved:
            fingerDidMove?(initialTouchPoint, endPoint)

            let deflection = determineDeflection(from: initialTouchPoint, to: endPoint)
            measurementsLog.append(Deflection(data: deflection))

            if let pointWithMaxDeviance = gesturePath.max(by: { (p1, p2) -> Bool in
                p1.distanceTo(lineSegmentBetween: initialTouchPoint, and: endPoint) < p2.distanceTo(lineSegmentBetween: initialTouchPoint, and: endPoint)
            }) {
                measurementsLog.append(LinearStrokeDeviance(data: Double(pointWithMaxDeviance.distanceTo(lineSegmentBetween: initialTouchPoint, and: endPoint))))

                if deflection != .eastStroke, deflection != .westStroke { // won't make much sense
                    let direction = determineDevianceDirection(from: initialTouchPoint, to: endPoint, lookingAt: pointWithMaxDeviance)
                    measurementsLog.append(LinearStrokeDevianceDirection(data: direction))
                }
            }

            if let strokeDuration = strokeDuration {
                measurementsLog.append(StrokeSpeed(data: Double(initialTouchPoint.distance(to: endPoint)) / strokeDuration))
            }
        default: ()
        }

        gesturePath.removeAll(keepingCapacity: false)
        state = .ended
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        initialTouchPoint = CGPoint.zero
        strokePhase = .notStarted
        trackedTouch = nil
        state = .cancelled
    }

    override public func reset() {
        super.reset()
        initialTouchPoint = CGPoint.zero
        strokePhase = .notStarted
        trackedTouch = nil
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

    /// Figure out the determinant of vectors (Start-End,Start-Point) to determin in which direction the point deviates.
    private func determineDevianceDirection(from start: CGPoint, to end: CGPoint, lookingAt point: CGPoint) -> Direction {
        if start.y == end.y {
            return .none
        }

        let sign = ((end.x - start.x) * (point.y - start.y) - (end.y - start.y) * (point.x - start.x)).sign

        switch sign {
        case .minus:
            return start.y > end.y ? .left : .right
        case .plus:
            return start.y > end.y ? .right : .left
        }
    }
}

// MARK: - Extensions

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
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
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
