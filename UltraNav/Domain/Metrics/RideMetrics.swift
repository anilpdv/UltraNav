import Foundation

struct RideMetrics: Equatable, Sendable {
    /// Current speed in meters per second.
    let currentSpeedMetersPerSecond: Double?

    /// Total accepted ride distance in meters.
    let distanceMeters: Double

    /// Current heart rate in beats per minute.
    let heartRateBeatsPerMinute: Int?

    /// Current cycling cadence in revolutions per minute.
    let cadenceRevolutionsPerMinute: Double?

    /// Current cycling power in watts.
    let powerWatts: Int?

    /// Current altitude in meters.
    let altitudeMeters: Double?

    static let empty = RideMetrics(
        currentSpeedMetersPerSecond: nil,
        distanceMeters: 0,
        heartRateBeatsPerMinute: nil,
        cadenceRevolutionsPerMinute: nil,
        powerWatts: nil,
        altitudeMeters: nil
    )
}
