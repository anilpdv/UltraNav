import Foundation

struct NavigationProgressState: Equatable, Sendable {
    private(set) var latestMatch: RouteMatch?
    private(set) var maximumDistanceAlongRouteMeters: Double = 0
    private(set) var currentCueID: NavigationCue.ID?
    private(set) var lastLocationTimestamp: Date?

    mutating func update(
        match: RouteMatch,
        locationTimestamp: Date
    ) {
        latestMatch = match
        maximumDistanceAlongRouteMeters = max(
            maximumDistanceAlongRouteMeters,
            match.distanceAlongRouteMeters
        )
        lastLocationTimestamp = locationTimestamp
    }

    mutating func updateCueID(_ cueID: NavigationCue.ID?) {
        currentCueID = cueID
    }

    mutating func reset() {
        self = NavigationProgressState()
    }
}
