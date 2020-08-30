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

public class TouchForce: GestureMeasurement {
    init(data: Double) {
        super.init(data: data)
    }
}

public class TouchRadius: GestureMeasurement {
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

class AggregatedNumericMeasurement {
    private(set) var last: GestureMeasurement?
    private var standardDeviation: Double {
        cardinality < 2 ? 0 : sqrt(variance / Double(max(1, cardinality - 1)))
    }

    private(set) var variance: Double = 0
    private(set) var mean: Double = 0
    private(set) var cardinality = 0

    func update(with measurement: GestureMeasurement) {
        if !(measurement.data is Double) { return }

        let oldMean = mean
        cardinality += 1

        setMean(newValue: measurement.data as! Double)
        setVariance(newValue: measurement.data as! Double, oldMean: oldMean)

        last = measurement
    }

    func setMean(newValue: Double) {
        mean = mean + ((newValue - mean) / Double(cardinality))
    }

    func setVariance(newValue: Double, oldMean: Double) {
        variance = variance + (newValue - oldMean) * (newValue - mean)
    }
}

class AggregatedEnumMeasurement {
    private(set) var last: GestureMeasurement?
    private(set) var counts: [String: Int] = [:]

    func update(with measurement: GestureMeasurement) {
        if measurement.data is Double || measurement.dataString == "" { return } // TODO: isEnum-ish check

        if counts[measurement.dataString] == nil {
            counts[measurement.dataString] = 0
        }

        counts[measurement.dataString]! += 1

        last = measurement
    }
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
    private var aggregatedNumericMeasurements: [String: AggregatedNumericMeasurement] = [:]
    private var aggregatedEnumMeasurements: [String: AggregatedEnumMeasurement] = [:]

    public var listDidChange: ((GestureMeasurement) -> Void)?
    public var jsonLog: Data? {
        let stringifiedMeasurements = measurements
            .map { $0.loggable }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = JSONEncoder.DateEncodingStrategy.iso8601
        encoder.outputFormatting = .prettyPrinted

        return try? encoder.encode(stringifiedMeasurements)
    }

    func append(_ measurement: GestureMeasurement) {
        measurements.append(measurement)

        if measurement.data is Double {
            guard let aggregatedMeasurement = aggregatedNumericMeasurements[String(describing: measurement.self)] else {
                let aggregatedMeasurement = AggregatedNumericMeasurement()
                aggregatedMeasurement.update(with: measurement)
                aggregatedNumericMeasurements[String(describing: measurement.self)] = aggregatedMeasurement

                return
            }

            aggregatedMeasurement.update(with: measurement)
        } else {
            guard let aggregatedMeasurement = aggregatedEnumMeasurements[String(describing: measurement.self)] else {
                let aggregatedMeasurement = AggregatedEnumMeasurement()
                aggregatedMeasurement.update(with: measurement)
                aggregatedEnumMeasurements[String(describing: measurement.self)] = aggregatedMeasurement

                return
            }

            aggregatedMeasurement.update(with: measurement)
        }
        listDidChange?(measurement)
    }
}
