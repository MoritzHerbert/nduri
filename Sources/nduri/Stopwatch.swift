//
//  Stopwatch.swift
//
//  Created by Moritz Herbert on 13.05.20.
//

import Foundation

final class Stopwatch {
    private var startTime: DispatchTime?
    private var endTime: DispatchTime?

    func start() {
        startTime = DispatchTime.now()
    }

    func stop() -> Double? {
        if startTime == nil { return nil }

        endTime = DispatchTime.now()

        return milliseconds
    }

    var milliseconds: Double? {
        guard let endTime = endTime,
            let startTime = startTime else {
            return nil
        }

        return Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000
    }

    var microseconds: Double? {
        guard let endTime = endTime,
            let startTime = startTime else {
            return nil
        }

        return Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1000
    }

    var nanoseconds: Double? {
        guard let endTime = endTime,
            let startTime = startTime else {
            return nil
        }

        return Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds)
    }
}
