import Foundation

/// Validates that a canonical domain Route satisfies all safety and geometric invariants before storage or navigation.
public final class CanonicalRouteValidator: RouteValidating, Sendable {
    public init() {}

    public func validate(route: Route) throws {
        // 1. Point Count Invariants
        guard !route.points.isEmpty else {
            throw RouteValidationFailure.emptyPoints
        }

        guard route.points.count >= 2 else {
            throw RouteValidationFailure.insufficientPoints(count: route.points.count, minimum: 2)
        }

        // 2. Identity & Name Invariants
        guard !route.id.rawValue.isEmpty else {
            throw RouteValidationFailure.emptyRouteID
        }

        guard !route.metadata.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RouteValidationFailure.emptyRouteName
        }

        // 3. Distance Invariants
        guard route.totalDistanceMeters >= 0.0,
              route.totalDistanceMeters.isFinite,
              !route.totalDistanceMeters.isNaN else {
            throw RouteValidationFailure.invalidDistance(route.totalDistanceMeters)
        }

        // 4. Point Coordinate & Distance Progression Invariants
        var previousDist = -0.001
        for pt in route.points {
            let lat = pt.coordinate.latitude
            let lon = pt.coordinate.longitude

            if lat.isNaN || lat.isInfinite || lat < -90.0 || lat > 90.0 ||
               lon.isNaN || lon.isInfinite || lon < -180.0 || lon > 180.0 {
                throw RouteValidationFailure.invalidCoordinate(pt.coordinate)
            }

            if pt.cumulativeDistanceMeters < previousDist {
                throw RouteValidationFailure.nonMonotonicCumulativeDistances
            }
            previousDist = pt.cumulativeDistanceMeters
        }

        // 5. Segment Invariants
        var lastEndIndex = -1
        for seg in route.segments {
            if seg.startPointIndex < 0 ||
               seg.endPointIndex >= route.points.count ||
               seg.startPointIndex > seg.endPointIndex {
                throw RouteValidationFailure.invalidSegmentIndices(
                    segmentIndex: seg.segmentIndex,
                    start: seg.startPointIndex,
                    end: seg.endPointIndex,
                    totalPoints: route.points.count
                )
            }

            if seg.startPointIndex <= lastEndIndex && lastEndIndex != -1 {
                throw RouteValidationFailure.segmentsOverlap
            }
            lastEndIndex = seg.endPointIndex
        }

        // 6. Waypoint Coordinate Invariants
        for wpt in route.waypoints {
            let lat = wpt.coordinate.latitude
            let lon = wpt.coordinate.longitude

            if lat.isNaN || lat.isInfinite || lat < -90.0 || lat > 90.0 ||
               lon.isNaN || lon.isInfinite || lon < -180.0 || lon > 180.0 {
                throw RouteValidationFailure.invalidWaypointCoordinate(wpt.coordinate)
            }
        }
    }
}
