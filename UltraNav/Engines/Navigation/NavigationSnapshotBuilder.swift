import Foundation

struct NavigationSnapshotBuilder: Sendable {
    func makeSnapshot(
        state: NavigationState,
        route: Route?,
        location: LocationSample?,
        match: RouteMatch?,
        cueProgress: CueProgress?,
        offRouteStatus: OffRouteStatus,
        failure: NavigationFailure?
    ) -> NavigationSnapshot {
        let distanceAlong = match?.distanceAlongRouteMeters ?? 0
        let totalDistance = route?.totalDistanceMeters ?? 0
        let remaining = max(0, totalDistance - distanceAlong)

        let progress: Double
        if totalDistance > 0 {
            progress = min(1.0, max(0.0, distanceAlong / totalDistance))
        } else {
            progress = 0
        }

        return NavigationSnapshot(
            state: state,
            routeID: route?.id,
            routeName: route?.metadata.name,
            routeProgress: progress,
            distanceAlongRouteMeters: distanceAlong,
            distanceRemainingMeters: remaining,
            crossTrackDistanceMeters: match?.crossTrackDistanceMeters,
            matchedCoordinate: match?.matchedCoordinate,
            matchedSegmentIndex: match?.segmentIndex,
            nextCue: cueProgress?.nextCue,
            distanceToNextCueMeters: cueProgress?.distanceToNextCueMeters,
            currentLocation: location?.coordinate,
            offRouteStatus: offRouteStatus,
            activeFailure: failure
        )
    }
}
