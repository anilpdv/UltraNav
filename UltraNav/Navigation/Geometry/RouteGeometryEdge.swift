import Foundation

/// Represents a single directed edge between two consecutive canonical route points.
public struct RouteGeometryEdge: Identifiable, Equatable, Sendable {
    public let index: Int
    public let startPoint: RoutePoint
    public let endPoint: RoutePoint
    public let lengthMeters: Double
    public let startDistanceMeters: Double
    public let endDistanceMeters: Double
    public let bearingDegrees: Double
    public let boundingBox: GeoBoundingBox

    public var id: Int { index }

    public init(
        index: Int,
        startPoint: RoutePoint,
        endPoint: RoutePoint
    ) {
        self.index = index
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.startDistanceMeters = startPoint.cumulativeDistanceMeters
        self.endDistanceMeters = endPoint.cumulativeDistanceMeters
        self.lengthMeters = max(0.0, endPoint.cumulativeDistanceMeters - startPoint.cumulativeDistanceMeters)
        self.bearingDegrees = startPoint.coordinate.initialBearing(to: endPoint.coordinate)
        self.boundingBox = GeoBoundingBox(coordinates: [startPoint.coordinate, endPoint.coordinate])
    }
}
