import Foundation

/// Protocol for generating deterministic RouteID values and fingerprints from coordinate geometry and content.
public protocol RouteIdentityCreating: Sendable {
    func makeRouteID(
        points: [Coordinate],
        segmentBreaks: [Int],
        version: RouteNormalizationVersion
    ) -> RouteID

    func makeFingerprints(
        points: [RoutePoint],
        segments: [RouteSegment],
        waypoints: [RouteWaypoint],
        version: RouteNormalizationVersion
    ) -> RouteFingerprints
}

public extension RouteIdentityCreating {
    func makeRouteID(points: [Coordinate], segmentBreaks: [Int]) -> RouteID {
        makeRouteID(points: points, segmentBreaks: segmentBreaks, version: .version2)
    }
}
