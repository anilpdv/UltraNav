import Foundation

struct NavigationSnapshot: Equatable, Sendable {
    let state: NavigationState

    /// Progress from 0.0 through 1.0.
    let routeProgress: Double

    /// Along-route distance from the route start, in meters.
    let distanceAlongRouteMeters: Double

    /// Along-route distance remaining, in meters.
    let distanceRemainingMeters: Double

    /// Distance from the matched route geometry, in meters.
    let crossTrackDistanceMeters: Double?

    let nextCue: NavigationCue?

    /// Along-route distance to the next cue, in meters.
    let distanceToNextCueMeters: Double?

    static let inactive = NavigationSnapshot(
        state: .inactive,
        routeProgress: 0,
        distanceAlongRouteMeters: 0,
        distanceRemainingMeters: 0,
        crossTrackDistanceMeters: nil,
        nextCue: nil,
        distanceToNextCueMeters: nil
    )
}
