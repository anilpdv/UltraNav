import Foundation

public protocol DurationFormatting: Sendable {
    func formatDuration(seconds: TimeInterval) -> String
}

public protocol SpeedFormatting: Sendable {
    func formatSpeed(
        metersPerSecond: Double,
        preferences: UnitPreferences
    ) -> MetricDisplayValue
}

public protocol DistanceFormatting: Sendable {
    func formatDistance(
        meters: Double,
        preferences: UnitPreferences
    ) -> MetricDisplayValue
}

public protocol ElevationFormatting: Sendable {
    func formatElevation(
        meters: Double,
        preferences: UnitPreferences
    ) -> MetricDisplayValue
}

public protocol GradientFormatting: Sendable {
    func formatGradient(
        ratio: Double
    ) -> MetricDisplayValue
}
