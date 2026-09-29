import Foundation

/// Fully validated, normalized domain representation of a navigable course.
public struct Route: Identifiable, Equatable, Hashable, Codable, Sendable {
    public typealias ID = RouteID

    public let id: RouteID
    public let metadata: RouteMetadata
    public let points: [RoutePoint]
    public let segments: [RouteSegment]
    public let waypoints: [RouteWaypoint]
    public let bounds: RouteBounds
    public let totalDistanceMeters: Double
    public let totalAscentMeters: Double?
    public let totalDescentMeters: Double?
    public let minimumElevationMeters: Double?
    public let maximumElevationMeters: Double?

    public init(
        id: RouteID,
        metadata: RouteMetadata,
        points: [RoutePoint],
        segments: [RouteSegment] = [],
        waypoints: [RouteWaypoint] = [],
        bounds: RouteBounds? = nil,
        totalDistanceMeters: Double,
        totalAscentMeters: Double? = nil,
        totalDescentMeters: Double? = nil,
        minimumElevationMeters: Double? = nil,
        maximumElevationMeters: Double? = nil
    ) {
        self.id = id
        self.metadata = metadata
        self.points = points
        self.segments = segments.isEmpty && !points.isEmpty
            ? [RouteSegment(segmentIndex: 0, startPointIndex: 0, endPointIndex: max(0, points.count - 1), distanceMeters: totalDistanceMeters)]
            : segments
        self.waypoints = waypoints
        self.bounds = bounds ?? Self.computeBounds(from: points)
        self.totalDistanceMeters = totalDistanceMeters
        self.totalAscentMeters = totalAscentMeters
        self.totalDescentMeters = totalDescentMeters
        self.minimumElevationMeters = minimumElevationMeters
        self.maximumElevationMeters = maximumElevationMeters
    }

    public init(
        id: UUID,
        metadata: RouteMetadata,
        points: [RoutePoint],
        totalDistanceMeters: Double
    ) {
        self.init(
            id: RouteID(uuid: id),
            metadata: metadata,
            points: points,
            segments: [],
            waypoints: [],
            bounds: nil,
            totalDistanceMeters: totalDistanceMeters,
            totalAscentMeters: nil,
            totalDescentMeters: nil,
            minimumElevationMeters: nil,
            maximumElevationMeters: nil
        )
    }

    private static func computeBounds(from points: [RoutePoint]) -> RouteBounds {
        guard let first = points.first else {
            return .zero
        }
        var minLat = first.coordinate.latitude
        var maxLat = first.coordinate.latitude
        var minLon = first.coordinate.longitude
        var maxLon = first.coordinate.longitude

        for pt in points {
            let lat = pt.coordinate.latitude
            let lon = pt.coordinate.longitude
            if lat < minLat { minLat = lat }
            if lat > maxLat { maxLat = lat }
            if lon < minLon { minLon = lon }
            if lon > maxLon { maxLon = lon }
        }

        return RouteBounds(
            minimumLatitude: minLat,
            maximumLatitude: maxLat,
            minimumLongitude: minLon,
            maximumLongitude: maxLon
        )
    }
}
