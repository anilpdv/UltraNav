import Foundation

/// Mathematical projection result of a point onto a route edge.
public struct SegmentProjectionResult: Equatable, Sendable {
    public let projectedCoordinate: Coordinate
    public let fraction: Double
    public let crossTrackDistanceMeters: Double
    public let distanceAlongRouteMeters: Double
    public let edgeBearingDegrees: Double

    public init(
        projectedCoordinate: Coordinate,
        fraction: Double,
        crossTrackDistanceMeters: Double,
        distanceAlongRouteMeters: Double,
        edgeBearingDegrees: Double
    ) {
        self.projectedCoordinate = projectedCoordinate
        self.fraction = fraction
        self.crossTrackDistanceMeters = crossTrackDistanceMeters
        self.distanceAlongRouteMeters = distanceAlongRouteMeters
        self.edgeBearingDegrees = edgeBearingDegrees
    }
}

/// Helper for projecting arbitrary coordinates onto route geometry edges.
public struct RouteSegmentProjector: Sendable {
    public init() {}

    /// Projects a target coordinate onto a route geometry edge.
    public func project(coordinate: Coordinate, onto edge: RouteGeometryEdge) -> SegmentProjectionResult {
        let p1 = edge.startPoint.coordinate
        let p2 = edge.endPoint.coordinate

        if edge.lengthMeters < 0.1 {
            let dist = coordinate.distance(to: p1)
            return SegmentProjectionResult(
                projectedCoordinate: p1,
                fraction: 0.0,
                crossTrackDistanceMeters: dist,
                distanceAlongRouteMeters: edge.startDistanceMeters,
                edgeBearingDegrees: edge.bearingDegrees
            )
        }

        let avgLat = (p1.latitude + p2.latitude + coordinate.latitude) / 3.0 * .pi / 180.0
        let cosLat = cos(avgLat)
        let metersPerDegreeLat = 111_139.0
        let metersPerDegreeLon = 111_139.0 * cosLat

        let ax = 0.0
        let ay = 0.0
        let bx = (p2.longitude - p1.longitude) * metersPerDegreeLon
        let by = (p2.latitude - p1.latitude) * metersPerDegreeLat
        let px = (coordinate.longitude - p1.longitude) * metersPerDegreeLon
        let py = (coordinate.latitude - p1.latitude) * metersPerDegreeLat

        let dx = bx - ax
        let dy = by - ay
        let segLengthSquared = dx * dx + dy * dy

        var t: Double = 0.0
        if segLengthSquared > 0.0001 {
            t = (px * dx + py * dy) / segLengthSquared
        }

        let clampedT = max(0.0, min(1.0, t))
        let projX = ax + clampedT * dx
        let projY = ay + clampedT * dy

        let distXP = px - projX
        let distYP = py - projY
        let crossTrack = sqrt(distXP * distXP + distYP * distYP)

        let projLat = p1.latitude + (projY / metersPerDegreeLat)
        let projLon = p1.longitude + (projX / metersPerDegreeLon)
        let projectedCoord = Coordinate(latitude: projLat, longitude: projLon)

        let alongRoute = edge.startDistanceMeters + clampedT * edge.lengthMeters

        return SegmentProjectionResult(
            projectedCoordinate: projectedCoord,
            fraction: clampedT,
            crossTrackDistanceMeters: crossTrack,
            distanceAlongRouteMeters: alongRoute,
            edgeBearingDegrees: edge.bearingDegrees
        )
    }
}
