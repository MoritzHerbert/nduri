//
//  Measurements.swift
//
//  Created by Moritz Herbert on 24.06.20.
//

import Foundation

// indicate deflection when e.g. scrolling
enum StrokePhases: String {
    case notStarted
    case initialPoint
    case moved
}

public enum Direction: String {
    case east
    case southeast
    case south
    case southwest
    case west
    case northwest
    case north
    case northeast
    case none
}

public enum MotionType: String {
    case stationary
    case notStationary
    case inMotion
}

// indicate where strokes took plase (should be used relative to scrollable areas)
public enum Grid {
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
    public private(set) var datetime: Date
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
    init(data: Direction) {
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

public class RelativeTapDevianceDirection: GestureMeasurement {
    init(data: Direction) {
        super.init(data: data)
    }
}

public class Motion: GestureMeasurement {
    init(data: MotionType) {
        super.init(data: data)
    }
}

/// Cannot easily make 'data: Any' from GestureMeasurement codable, therefore this intermediate struct is used for JSON parsing
public struct LoggableMeasurement: Codable {
    var event: String
    var data: String
    var datetime: Date
}

extension GestureMeasurement {
    var loggable: LoggableMeasurement {
        LoggableMeasurement(event: String(describing: type(of: self)),
                            data: dataString,
                            datetime: datetime)
    }
}

public class MeasurementsList {
    private var measurements: [GestureMeasurement] = []

    public var listDidChange: ((GestureMeasurement) -> Void)?
    public var jsonLog: Data? {
        let stringifiedMeasurements = measurements
            .map { $0.loggable }

        let encoder = JSONEncoder()

        return try? encoder.encode(stringifiedMeasurements)
    }

    func append(_ measurement: GestureMeasurement) {
        measurements.append(measurement)
        listDidChange?(measurement)
    }
}
