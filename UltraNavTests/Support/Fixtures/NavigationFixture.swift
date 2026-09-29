import Foundation
@testable import UltraNav

/// Standardized navigation fixtures for route matching, cues, and navigation snapshots.
enum NavigationFixture {
    static func routeMatch(
        matchedCoordinate: Coordinate = Coordinate(latitude: 24.7150, longitude: 46.6753),
        distanceAlongRouteMeters: Double = 150.0,
        distanceFromRouteMeters: Double = 2.0,
        segmentIndex: Int = 0
    ) -> RouteMatch {
        RouteMatch(
            matchedCoordinate: matchedCoordinate,
            segmentIndex: segmentIndex,
            segmentFraction: 0,
            distanceAlongRouteMeters: distanceAlongRouteMeters,
            crossTrackDistanceMeters: distanceFromRouteMeters
        )
    }

    static func cue(
        id: UUID = UUID(),
        maneuver: NavigationManeuver = .right,
        coordinate: Coordinate = Coordinate(latitude: 24.7150, longitude: 46.6753),
        routeDistanceMeters: Double = 500.0,
        instruction: String? = "Turn right onto Mountain Rd"
    ) -> NavigationCue {
        NavigationCue(
            id: id,
            maneuver: maneuver,
            coordinate: coordinate,
            routeDistanceMeters: routeDistanceMeters,
            instruction: instruction
        )
    }

    static func snapshot(
        state: NavigationState = .navigating,
        routeID: Route.ID? = TestIDs.routeAlpha,
        routeName: String? = "Test Route",
        routeProgress: Double = 0.25,
        distanceAlongRouteMeters: Double = 250.0,
        distanceRemainingMeters: Double = 750.0,
        crossTrackDistanceMeters: Double? = 1.5,
        matchedCoordinate: Coordinate? = Coordinate(latitude: 24.7150, longitude: 46.6753),
        matchedSegmentIndex: Int? = 0,
        nextCue: NavigationCue? = cue(),
        distanceToNextCueMeters: Double? = 250.0,
        currentLocation: Coordinate? = Coordinate(latitude: 24.7150, longitude: 46.6753),
        offRouteStatus: OffRouteStatus = .onRoute,
        activeFailure: NavigationFailure? = nil
    ) -> NavigationSnapshot {
        NavigationSnapshot(
            state: state,
            routeID: routeID,
            routeName: routeName,
            routeProgress: routeProgress,
            distanceAlongRouteMeters: distanceAlongRouteMeters,
            distanceRemainingMeters: distanceRemainingMeters,
            crossTrackDistanceMeters: crossTrackDistanceMeters,
            matchedCoordinate: matchedCoordinate,
            matchedSegmentIndex: matchedSegmentIndex,
            nextCue: nextCue,
            distanceToNextCueMeters: distanceToNextCueMeters,
            currentLocation: currentLocation,
            offRouteStatus: offRouteStatus,
            activeFailure: activeFailure
        )
    }
}
