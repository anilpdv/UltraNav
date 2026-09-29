import Foundation

struct NavigationSnapshot: Equatable, Sendable {
    let state: NavigationState

    let routeID: Route.ID?
    let routeName: String?

    /// Progress from 0.0 through 1.0.
    let routeProgress: Double

    /// Along-route distance from the route start, in meters.
    let distanceAlongRouteMeters: Double

    /// Along-route distance remaining, in meters.
    let distanceRemainingMeters: Double

    /// Distance from the matched route geometry, in meters.
    let crossTrackDistanceMeters: Double?

    let matchedCoordinate: Coordinate?
    let matchedSegmentIndex: Int?

    let nextCue: NavigationCue?

    /// Along-route distance to the next cue, in meters.
    let distanceToNextCueMeters: Double?

    let currentLocation: Coordinate?
    let offRouteStatus: OffRouteStatus
    let activeFailure: NavigationFailure?

    init(
        state: NavigationState,
        routeID: Route.ID? = nil,
        routeName: String? = nil,
        routeProgress: Double,
        distanceAlongRouteMeters: Double,
        distanceRemainingMeters: Double,
        crossTrackDistanceMeters: Double? = nil,
        matchedCoordinate: Coordinate? = nil,
        matchedSegmentIndex: Int? = nil,
        nextCue: NavigationCue? = nil,
        distanceToNextCueMeters: Double? = nil,
        currentLocation: Coordinate? = nil,
        offRouteStatus: OffRouteStatus = .unknown,
        activeFailure: NavigationFailure? = nil
    ) {
        self.state = state
        self.routeID = routeID
        self.routeName = routeName
        self.routeProgress = routeProgress
        self.distanceAlongRouteMeters = distanceAlongRouteMeters
        self.distanceRemainingMeters = distanceRemainingMeters
        self.crossTrackDistanceMeters = crossTrackDistanceMeters
        self.matchedCoordinate = matchedCoordinate
        self.matchedSegmentIndex = matchedSegmentIndex
        self.nextCue = nextCue
        self.distanceToNextCueMeters = distanceToNextCueMeters
        self.currentLocation = currentLocation
        self.offRouteStatus = offRouteStatus
        self.activeFailure = activeFailure
    }

    static let inactive = NavigationSnapshot(
        state: .inactive,
        routeID: nil,
        routeName: nil,
        routeProgress: 0,
        distanceAlongRouteMeters: 0,
        distanceRemainingMeters: 0,
        crossTrackDistanceMeters: nil,
        matchedCoordinate: nil,
        matchedSegmentIndex: nil,
        nextCue: nil,
        distanceToNextCueMeters: nil,
        currentLocation: nil,
        offRouteStatus: .unknown,
        activeFailure: nil
    )
}
