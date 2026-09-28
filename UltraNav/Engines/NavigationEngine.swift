import Foundation
import CoreLocation

/// Autonomous navigation engine managing route progress, XTE, off-course detection, and turn cues.
@MainActor
final class NavigationEngine {
    private(set) var activeRoute: GPXRoute?
    private(set) var navigationState: NavigationState = .inactive
    private(set) var breadcrumbTrail: [Coordinate] = []

    private(set) var crossTrackErrorMeters: Double?
    private(set) var isOffCourse: Bool = false
    private(set) var nextCue: RouteCue?
    private(set) var distanceToNextCueMeters: Double?
    private(set) var distanceAlongRouteMeters: Double = 0
    private(set) var distanceRemainingMeters: Double = 0
    private(set) var routeProgress: Double = 0

    init(route: GPXRoute? = nil) {
        self.activeRoute = route
        if let route {
            self.navigationState = .navigating
            self.distanceRemainingMeters = route.totalDistance
        }
    }

    func load(route: GPXRoute) {
        self.activeRoute = route
        self.navigationState = .navigating
        self.breadcrumbTrail = []
        self.isOffCourse = false
        self.crossTrackErrorMeters = 0
        self.distanceAlongRouteMeters = 0
        self.routeProgress = 0
        self.distanceRemainingMeters = route.totalDistance
        self.nextCue = route.cues.first
        self.distanceToNextCueMeters = route.cues.first?.distanceFromStart
    }

    func reset() {
        self.activeRoute = nil
        self.navigationState = .inactive
        self.breadcrumbTrail = []
        self.crossTrackErrorMeters = nil
        self.isOffCourse = false
        self.nextCue = nil
        self.distanceToNextCueMeters = nil
        self.distanceAlongRouteMeters = 0
        self.routeProgress = 0
        self.distanceRemainingMeters = 0
    }

    func update(location: LocationSample) {
        breadcrumbTrail.append(location.coordinate)

        guard let route = activeRoute, !route.points.isEmpty else {
            return
        }

        // Find nearest route point
        // TODO(PHASE-5): Replace legacy Euclidean search with Douglas-Peucker projection
        var minDistance: Double = .infinity
        var closestIndex = 0

        for (idx, pt) in route.points.enumerated() {
            let ptCoord = Coordinate(latitude: pt.coordinate.latitude, longitude: pt.coordinate.longitude)
            let dist = location.coordinate.distance(to: ptCoord)
            if dist < minDistance {
                minDistance = dist
                closestIndex = idx
            }
        }

        self.crossTrackErrorMeters = minDistance

        // Off-course hysteresis: 35m off, 25m recovery
        if minDistance > 35 && !isOffCourse {
            isOffCourse = true
            navigationState = .offRoute
        } else if minDistance <= 25 && isOffCourse {
            isOffCourse = false
            navigationState = .navigating
        }

        let userProgressDist = route.points[closestIndex].distanceFromStart
        self.distanceAlongRouteMeters = userProgressDist
        self.distanceRemainingMeters = max(0, route.totalDistance - userProgressDist)
        self.routeProgress = route.totalDistance > 0 ? min(1.0, userProgressDist / route.totalDistance) : 0

        // Find upcoming turn cue
        if let upcoming = route.cues.first(where: { $0.distanceFromStart >= (userProgressDist - 25) }) {
            self.nextCue = upcoming
            self.distanceToNextCueMeters = max(0, upcoming.distanceFromStart - userProgressDist)
        } else {
            self.nextCue = route.cues.last
            self.distanceToNextCueMeters = max(0, route.totalDistance - userProgressDist)
        }
    }

    var snapshot: NavigationSnapshot {
        NavigationSnapshot(
            state: navigationState,
            routeProgress: routeProgress,
            distanceAlongRouteMeters: distanceAlongRouteMeters,
            distanceRemainingMeters: distanceRemainingMeters,
            crossTrackDistanceMeters: crossTrackErrorMeters,
            nextCue: nextCue.map { cue in
                NavigationCue(
                    id: cue.id,
                    maneuver: .unknown,
                    coordinate: Coordinate(latitude: cue.coordinate.latitude, longitude: cue.coordinate.longitude),
                    routeDistanceMeters: cue.distanceFromStart,
                    instruction: cue.instruction
                )
            },
            distanceToNextCueMeters: distanceToNextCueMeters
        )
    }
}
