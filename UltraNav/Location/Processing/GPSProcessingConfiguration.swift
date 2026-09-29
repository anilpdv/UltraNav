import Foundation

/// Configuration parameters and thresholds governing GPS filtering, movement detection, and distance accumulation.
public struct GPSProcessingConfiguration: Equatable, Sendable {
    public let maximumHorizontalAccuracyMeters: Double
    public let preferredHorizontalAccuracyMeters: Double
    public let maximumSampleAgeSeconds: TimeInterval
    public let minimumTimeDeltaSeconds: TimeInterval
    public let maximumTimeDeltaForDistanceSeconds: TimeInterval
    public let maximumPlausibleSpeedMetersPerSecond: Double
    public let stationarySpeedThresholdMetersPerSecond: Double
    public let movingSpeedThresholdMetersPerSecond: Double
    public let minimumMovementDistanceMeters: Double
    public let accuracyOverlapMultiplier: Double
    public let movementConfirmationSamples: Int
    public let stationaryConfirmationSamples: Int
    public let speedFreshnessSeconds: TimeInterval
    public let smoothingWindowSeconds: TimeInterval

    public init(
        maximumHorizontalAccuracyMeters: Double = 25.0,
        preferredHorizontalAccuracyMeters: Double = 10.0,
        maximumSampleAgeSeconds: TimeInterval = 15.0,
        minimumTimeDeltaSeconds: TimeInterval = 0.25,
        maximumTimeDeltaForDistanceSeconds: TimeInterval = 30.0,
        maximumPlausibleSpeedMetersPerSecond: Double = 35.0,
        stationarySpeedThresholdMetersPerSecond: Double = 0.8,
        movingSpeedThresholdMetersPerSecond: Double = 1.5,
        minimumMovementDistanceMeters: Double = 3.0,
        accuracyOverlapMultiplier: Double = 1.0,
        movementConfirmationSamples: Int = 2,
        stationaryConfirmationSamples: Int = 3,
        speedFreshnessSeconds: TimeInterval = 5.0,
        smoothingWindowSeconds: TimeInterval = 5.0
    ) {
        self.maximumHorizontalAccuracyMeters = maximumHorizontalAccuracyMeters
        self.preferredHorizontalAccuracyMeters = preferredHorizontalAccuracyMeters
        self.maximumSampleAgeSeconds = maximumSampleAgeSeconds
        self.minimumTimeDeltaSeconds = minimumTimeDeltaSeconds
        self.maximumTimeDeltaForDistanceSeconds = maximumTimeDeltaForDistanceSeconds
        self.maximumPlausibleSpeedMetersPerSecond = maximumPlausibleSpeedMetersPerSecond
        self.stationarySpeedThresholdMetersPerSecond = stationarySpeedThresholdMetersPerSecond
        self.movingSpeedThresholdMetersPerSecond = movingSpeedThresholdMetersPerSecond
        self.minimumMovementDistanceMeters = minimumMovementDistanceMeters
        self.accuracyOverlapMultiplier = accuracyOverlapMultiplier
        self.movementConfirmationSamples = movementConfirmationSamples
        self.stationaryConfirmationSamples = stationaryConfirmationSamples
        self.speedFreshnessSeconds = speedFreshnessSeconds
        self.smoothingWindowSeconds = smoothingWindowSeconds
    }

    public static let outdoorCycling = GPSProcessingConfiguration()
}
