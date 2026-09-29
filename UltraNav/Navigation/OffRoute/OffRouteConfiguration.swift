import Foundation

/// Configuration parameters for off-route deviation detection, persistence, and recovery thresholds.
struct OffRouteConfiguration: Equatable, Sendable {
    var suspectedDistanceThresholdMeters: Double
    var confirmedDistanceThresholdMeters: Double
    var recoveryDistanceThresholdMeters: Double
    var consecutiveEvidenceCount: Int
    var confirmationDurationSeconds: TimeInterval
    var maximumHeadingDifferenceDegrees: Double

    init(
        suspectedDistanceThresholdMeters: Double = 35.0,
        confirmedDistanceThresholdMeters: Double = 55.0,
        recoveryDistanceThresholdMeters: Double = 20.0,
        consecutiveEvidenceCount: Int = 3,
        confirmationDurationSeconds: TimeInterval = 5.0,
        maximumHeadingDifferenceDegrees: Double = 90.0
    ) {
        self.suspectedDistanceThresholdMeters = suspectedDistanceThresholdMeters
        self.confirmedDistanceThresholdMeters = confirmedDistanceThresholdMeters
        self.recoveryDistanceThresholdMeters = recoveryDistanceThresholdMeters
        self.consecutiveEvidenceCount = consecutiveEvidenceCount
        self.confirmationDurationSeconds = confirmationDurationSeconds
        self.maximumHeadingDifferenceDegrees = maximumHeadingDifferenceDegrees
    }
}
