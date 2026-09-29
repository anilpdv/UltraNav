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
