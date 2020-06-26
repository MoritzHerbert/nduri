//
//  GenericGestureRecognizer.swift
//
//  Created by Moritz Herbert on 31.03.20.
//

import CoreMotion
import UIKit

public class GenericGestureRecognizer: UIGestureRecognizer {
    private var strokePhase: StrokePhases = .notStarted
    private var initialTouchPoint = CGPoint.zero
    private var trackedTouch: UITouch?
    public private(set) var measurementsLog = MeasurementsList()
    private var motionManager: CMMotionManager!
    private var motionActivityManager: CMMotionActivityManager!
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
        gesturePath = []

        #if !targetEnvironment(simulator)
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        motionTimer = Timer.scheduledTimer(withTimeInterval: 5,
                                           repeats: true,
                                           block: { _ in

                                            if let accelerometerData = motionManager.accelerometerData {
                                                print(accelerometerData.acceleration.x)
                                            }
        })

        if CMMotionActivityManager.isActivityAvailable() {
            motionActivityManager = CMMotionActivityManager()
            motionActivityManager.startActivityUpdates(to: OperationQueue.main) { motion in
                print("staitionary", motion!.stationary)
                print("walking", motion!.walking)
                print("confidence", motion!.confidence)

//
//                self.isStationaryLabel.text = (motion?.stationary)! ? "True" : "False"
//                self.isWalkingLabel.text = (motion?.walking)! ? "True" : "False"
//                if motion?.confidence == CMMotionActivityConfidence.low {
//                    self.confidenceLabel.text = "Low"
//                } else if motion?.confidence == CMMotionActivityConfidence.medium {
//                    self.confidenceLabel.text = "Medium"
//                } else if motion?.confidence == CMMotionActivityConfidence.high {
//                    self.confidenceLabel.text = "High"
//                }
            }
        }
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
            initialTouchPoint = trackedTouch!.location(in: nil)
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

        gesturePath.append(newTouch.location(in: nil))
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        _ = tapStopwatch.stop()
        let strokeDuration = strokeStopwatch.stop()

        guard let newTouch = touches.first, newTouch == trackedTouch else {
            state = .failed
            return
        }

        let endPoint = newTouch.location(in: nil)

        switch strokePhase {
        case .initialPoint:
            if #available(iOS 9.1, *), !newTouch.force.isZero {
                let force = newTouch.force
                let normalisedForce = force / newTouch.maximumPossibleForce

                measurementsLog.append(Force(data: Double(normalisedForce.isNaN ? force : normalisedForce)))
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

                if deflection != .east, deflection != .west { // won't make much sense
                    let direction = determineDirection(from: initialTouchPoint, to: endPoint, lookingAt: pointWithMaxDeviance)
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

    private func determineDeflection(from start: CGPoint, to end: CGPoint) -> Direction { // TODO: Revisit slope numbers
        let slope = start.slope(to: end)

        if slope < -2 {
            return start.x <= end.x ? .north : .south
        } else if slope < -0.5 {
            return start.x <= end.x ? .northeast : .southwest
        } else if slope < 0.5 {
            return start.x <= end.x ? .east : .west
        } else if slope < 2 {
            return start.x <= end.x ? .southeast : .northwest
        }

        return start.x <= end.x ? .south : .north
    }

    /// Figure out the determinant of vectors (Start-End,Start-Point) to determine in which direction the point deviates.
    private func determineDirection(from start: CGPoint, to end: CGPoint, lookingAt point: CGPoint) -> Direction {
        if start.y == end.y {
            return .none
        }

        let sign = ((end.x - start.x) * (point.y - start.y) - (end.y - start.y) * (point.x - start.x)).sign

        switch sign {
        case .minus:
            return start.y > end.y ? .west : .east
        case .plus:
            return start.y > end.y ? .east : .west
        }
    }

    private func determineDirection(from point1: CGPoint, lookingAt point2: CGPoint) -> Direction {
        switch (point1.x, point1.y, point2.x, point2.y) {
        case let(x1, y1, x2, y2) where y1 == y2 && x1 == x2:
            return .none
        case let(x1, y1, x2, y2) where y1 == y2 && x1 < x2:
            return .west
        case let(x1, y1, x2, y2) where y1 == y2 && x1 > x2:
            return .east
        case let(x1, y1, x2, y2) where y1 < y2 && x1 == x2:
            return .south
        case let(x1, y1, x2, y2) where y1 < y2 && x1 < x2:
            return .southwest
        case let(x1, y1, x2, y2) where y1 < y2 && x1 > x2:
            return .southeast
        case let(x1, y1, x2, y2) where y1 > y2 && x1 == x2:
            return .north
        case let(x1, y1, x2, y2) where y1 > y2 && x1 < x2:
            return .northwest
        case let(x1, y1, x2, y2) where y1 > y2 && x1 > x2:
            return .northeast
        default:
            return .none
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
