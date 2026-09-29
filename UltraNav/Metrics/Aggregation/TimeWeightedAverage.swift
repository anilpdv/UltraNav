import Foundation

struct TimeWeightedSample: Equatable, Sendable {
    let value: Double
    let durationSeconds: TimeInterval
}

protocol TimeWeightedAverageCalculating: Sendable {
    func calculateAverage(samples: [TimeWeightedSample]) -> Double?
}

struct TimeWeightedAverageCalculator: TimeWeightedAverageCalculating, Sendable {
    func calculateAverage(samples: [TimeWeightedSample]) -> Double? {
        guard !samples.isEmpty else { return nil }
        let totalDuration = samples.reduce(0.0) { $0 + $1.durationSeconds }
        guard totalDuration > 0 else { return nil }
        let weightedSum = samples.reduce(0.0) { $0 + ($1.value * $1.durationSeconds) }
        return weightedSum / totalDuration
    }
}

struct TimeWeightedAverage: Equatable, Sendable {
    private(set) var weightedSum: Double = 0
    private(set) var totalDurationSeconds: TimeInterval = 0

    private var lastValue: Double?
    private var lastTimestamp: Date?

    mutating func consume(
        value: Double,
        at timestamp: Date,
        maximumIntervalSeconds: TimeInterval
    ) {
        guard value.isFinite else { return }

        if let prevVal = lastValue, let prevTime = lastTimestamp {
            let dt = timestamp.timeIntervalSince(prevTime)
            if dt > 0 {
                let boundedDt = min(dt, maximumIntervalSeconds)
                weightedSum += prevVal * boundedDt
                totalDurationSeconds += boundedDt
            }
        }

        lastValue = value
        lastTimestamp = timestamp
    }

    mutating func stop(at timestamp: Date, maximumIntervalSeconds: TimeInterval = 5.0) {
        if let prevVal = lastValue, let prevTime = lastTimestamp {
            let dt = timestamp.timeIntervalSince(prevTime)
            if dt > 0 {
                let boundedDt = min(dt, maximumIntervalSeconds)
                weightedSum += prevVal * boundedDt
                totalDurationSeconds += boundedDt
            }
        }
        lastValue = nil
        lastTimestamp = nil
    }

    var average: Double? {
        guard totalDurationSeconds > 0 else {
            return nil
        }
        return weightedSum / totalDurationSeconds
    }

    mutating func reset() {
        weightedSum = 0
        totalDurationSeconds = 0
        lastValue = nil
        lastTimestamp = nil
    }
}
