import Foundation

struct LocationConfiguration: Equatable, Sendable {
    /// Requested horizontal accuracy in meters.
    let desiredAccuracyMeters: Double

    /// Minimum movement in meters before the platform should
    /// normally deliver another location.
    let distanceFilterMeters: Double

    /// Whether the platform may automatically pause updates.
    let pausesAutomatically: Bool

    /// Whether background location updates are requested.
    let allowsBackgroundUpdates: Bool

    static let cycling = LocationConfiguration(
        desiredAccuracyMeters: 10,
        distanceFilterMeters: 2,
        pausesAutomatically: false,
        allowsBackgroundUpdates: true
    )
}
