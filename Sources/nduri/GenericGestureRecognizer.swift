//
//  GenericGestureRecognizer.swift
//
//  Created by Moritz Herbert on 31.03.20.
//

import CoreMotion
import UIKit

@available(iOS 10.0, *)
public class GenericGestureRecognizer: UIGestureRecognizer {
    private var strokePhase: StrokePhases = .notStarted
    private var initialTouchPoint = CGPoint.zero
    private var trackedTouch: UITouch?

    private var motionManager: CMMotionManager!
    private var motionActivityManager: CMMotionActivityManager!
    private var motionTimer: Timer?
    private var gestureStopwatch = Stopwatch()

    public var fingerDidMove: ((CGPoint, CGPoint) -> Void)?
    public var gesturePath: [CGPoint] = []
    public var gestureEnded: (() -> Void)?
    public var measurementCreated: ((GestureMeasurement) -> Void)?

    public init(target: UIView) {
        super.init(target: target, action: nil)

        #if !targetEnvironment(simulator)
            motionManager = CMMotionManager()
            motionManager.startDeviceMotionUpdates()
            motionTimer = Timer.scheduledTimer(withTimeInterval: 1,
                                               repeats: true,
                                               block: { [unowned self] _ in
                                                   if let pitch = self.motionManager.deviceMotion?.attitude.pitch {
                                                       self.measurementCreated?(Tilt(data: pitch))
                                                   }
                                               })
        #endif

        if CMMotionActivityManager.isActivityAvailable() {
            motionActivityManager = CMMotionActivityManager()
            motionActivityManager.startActivityUpdates(to: OperationQueue.main) { [unowned self] motion in
                if motion?.confidence != CMMotionActivityConfidence.low, motion?.unknown == false {
                    switch (motion?.stationary, motion?.walking, motion?.running, motion?.automotive, motion?.cycling) {
                    case (true, false, false, false, false):
                        self.measurementCreated?(Motion(data: .stationary))
                    case (false, false, false, false, false):
                        self.measurementCreated?(Motion(data: .notStationary))
                    default:
                        self.measurementCreated?(Motion(data: .inMotion))
                    }
                }
            }
        }
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        gestureStopwatch.start()

        gesturePath.removeAll()

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
        let gestureDurationInMilliseconds = gestureStopwatch.stop()

        guard let newTouch = touches.first, newTouch == trackedTouch else {
            state = .failed
            return
        }

        let endPoint = newTouch.location(in: nil)

        switch strokePhase {
        case .initialPoint:
            if !newTouch.force.isZero {
                measurementCreated?(TouchForce(data: Double(newTouch.force)))
            }

            measurementCreated?(TouchRadius(data: Double(newTouch.majorRadius)))

            if let tapDuration = gestureStopwatch.microseconds {
                measurementCreated?(TapDuration(data: tapDuration))
            }

            let frameOfTouchedView = newTouch.frameOfTouchedView(startingIn: view!)
            if frameOfTouchedView?.width ?? 0.0 > 50.0 || frameOfTouchedView?
                .height ?? 0.0 > 50.0 { // for very small views/buttons, that measurement might be useless
                let directionToCenterOfTouchedView = determineDirection(from: newTouch.location(in: nil),
                                                                        lookingAt: CGPoint(x: frameOfTouchedView!.midX, y: frameOfTouchedView!.midY))

                measurementCreated?(RelativeTapDevianceDirection(data: directionToCenterOfTouchedView))
            }
        case .moved:
            fingerDidMove?(initialTouchPoint, endPoint)

            if initialTouchPoint.distance(to: endPoint) < 40 {
                let deflection = determineDeflection(from: initialTouchPoint, to: endPoint)
                measurementCreated?(Deflection(data: deflection))

                if !newTouch.force.isZero {
                    measurementCreated?(TouchForce(data: Double(newTouch.force)))
                }

                measurementCreated?(TouchRadius(data: Double(newTouch.majorRadius)))

                if let tapDuration = gestureStopwatch.microseconds {
                    measurementCreated?(TapDuration(data: tapDuration))
                }

                let frameOfTouchedView = newTouch.frameOfTouchedView(startingIn: view!)
                if frameOfTouchedView?.width ?? 0.0 > 50.0 || frameOfTouchedView?
                    .height ?? 0.0 > 50.0 { // for very small views/buttons, that measurement might be useless
                    let directionToCenterOfTouchedView = determineDirection(from: newTouch.location(in: nil),
                                                                            lookingAt: CGPoint(x: frameOfTouchedView!.midX, y: frameOfTouchedView!.midY))

                    measurementCreated?(RelativeTapDevianceDirection(data: directionToCenterOfTouchedView))
                }
            } else {
                if let pointWithMaxDeviance = gesturePath.max(by: { (p1, p2) -> Bool in
                    p1.distanceTo(lineSegmentBetween: initialTouchPoint, and: endPoint) < p2.distanceTo(lineSegmentBetween: initialTouchPoint, and: endPoint)
                }) {
                    measurementCreated?(LinearStrokeDeviance(data: Double(pointWithMaxDeviance.distanceTo(lineSegmentBetween: initialTouchPoint, and: endPoint))))

                    let direction = determineDirection(from: initialTouchPoint, to: endPoint, lookingAt: pointWithMaxDeviance)
                    measurementCreated?(LinearStrokeDevianceDirection(data: direction))
                }

                measurementCreated?(StrokeDistance(data: Double(initialTouchPoint.distance(to: endPoint))))

                if let gestureDurationInMilliseconds = gestureDurationInMilliseconds {
                    measurementCreated?(StrokeSpeed(data: Double(initialTouchPoint.distance(to: endPoint)) / gestureDurationInMilliseconds))
                }
            }
        default: ()
        }

        if let gestureEnded = gestureEnded {
            gestureEnded()
        }

        state = .ended
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        initialTouchPoint = CGPoint.zero
        strokePhase = .notStarted
        trackedTouch = nil

        if let gestureEnded = gestureEnded {
            gestureEnded()
        }

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
        switch (point1.x, point1.y, point2.x, point2.y) { // TODO: add some points tolerance to the equals cases, otherwise n, s, e, w would hardly be hit
        case let (x1, y1, x2, y2) where y1 == y2 && x1 == x2:
            return .none
        case let (x1, y1, x2, y2) where y1 == y2 && x1 < x2:
            return .west
        case let (x1, y1, x2, y2) where y1 == y2 && x1 > x2:
            return .east
        case let (x1, y1, x2, y2) where y1 < y2 && x1 == x2:
            return .north
        case let (x1, y1, x2, y2) where y1 > y2 && x1 == x2:
            return .south
        case let (x1, y1, x2, y2) where y1 < y2 && x1 < x2:
            return .northwest
        case let (x1, y1, x2, y2) where y1 < y2 && x1 > x2:
            return .northeast
        case let (x1, y1, x2, y2) where y1 > y2 && x1 < x2:
            return .southwest
        case let (x1, y1, x2, y2) where y1 > y2 && x1 > x2:
            return .southeast
        default:
            return .none
        }
    }
}
