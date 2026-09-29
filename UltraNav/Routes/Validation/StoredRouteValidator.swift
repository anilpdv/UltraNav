import Foundation

/// Validates that a domain Route object satisfies all structural invariants before storage or navigation.
public final class StoredRouteValidator: RouteValidating, Sendable {
    public init() {}

    public func validate(route: Route) throws {
        guard !route.points.isEmpty else {
            throw RouteValidationFailure.emptyPoints
        }

        guard route.totalDistanceMeters >= 0 && !route.totalDistanceMeters.isNaN && !route.totalDistanceMeters.isInfinite else {
            throw RouteValidationFailure.invalidDistance(route.totalDistanceMeters)
        }

        var previousDist = -0.001
        for (idx, pt) in route.points.enumerated() {
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

        // Validate segments
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
        }
    }
}
