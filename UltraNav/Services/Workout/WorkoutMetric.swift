import Foundation

enum WorkoutMetric: Equatable, Sendable {
    case heartRate(
        beatsPerMinute: Double,
        timestamp: Date
    )
    case activeEnergy(
        kilocalories: Double,
        timestamp: Date
    )
    case cyclingDistance(
        meters: Double,
        timestamp: Date
    )
}
