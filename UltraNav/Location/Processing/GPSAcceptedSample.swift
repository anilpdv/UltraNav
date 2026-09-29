import Foundation

/// Validated and processed GPS position accepted for ride metrics and navigation.
public struct GPSAcceptedSample: Equatable, Sendable {
    public let sample: LocationSample
    public let quality: GPSQuality
    public let selectedSpeedMetersPerSecond: Double?
    public let movementState: MovementState
    public let distanceIncrementMeters: Double
    public let totalDistanceMeters: Double
    public let sequence: UInt64
    public let suitableForRideMetrics: Bool
    public let suitableForNavigation: Bool

    public init(
        sample: LocationSample,
        quality: GPSQuality,
        selectedSpeedMetersPerSecond: Double?,
        movementState: MovementState,
        distanceIncrementMeters: Double,
        totalDistanceMeters: Double,
        sequence: UInt64,
        suitableForRideMetrics: Bool = true,
        suitableForNavigation: Bool = true
    ) {
        self.sample = sample
        self.quality = quality
        self.selectedSpeedMetersPerSecond = selectedSpeedMetersPerSecond
        self.movementState = movementState
        self.distanceIncrementMeters = distanceIncrementMeters
        self.totalDistanceMeters = totalDistanceMeters
        self.sequence = sequence
        self.suitableForRideMetrics = suitableForRideMetrics
        self.suitableForNavigation = suitableForNavigation
    }
}
