import Foundation

/// Snapshot of the active navigation state and trajectory providing context for rejoin candidate search.
struct RejoinSearchContext: Equatable, Sendable {
    let routeID: Route.ID
    let lastStableMatch: RouteMatch?
    let maximumReachedDistanceMeters: Double
    let travelDirectionBeforeDeviation: NavigationTravelDirection
    let currentMovementState: MovementState
    let currentLocation: GPSAcceptedSample
    let currentEpisode: OffRouteEpisode
    let previousCandidate: RejoinCandidate?

    init(
        routeID: Route.ID,
        lastStableMatch: RouteMatch?,
        maximumReachedDistanceMeters: Double,
        travelDirectionBeforeDeviation: NavigationTravelDirection,
        currentMovementState: MovementState,
        currentLocation: GPSAcceptedSample,
        currentEpisode: OffRouteEpisode,
        previousCandidate: RejoinCandidate? = nil
    ) {
        self.routeID = routeID
        self.lastStableMatch = lastStableMatch
        self.maximumReachedDistanceMeters = maximumReachedDistanceMeters
        self.travelDirectionBeforeDeviation = travelDirectionBeforeDeviation
        self.currentMovementState = currentMovementState
        self.currentLocation = currentLocation
        self.currentEpisode = currentEpisode
        self.previousCandidate = previousCandidate
    }
}
