import Foundation

/// Represents a distinct continuous segment within a route's points array.
public struct RouteSegment: Identifiable, Equatable, Hashable, Codable, Sendable {
    public let id: UUID
    public let segmentIndex: Int
    public let startPointIndex: Int
    public let endPointIndex: Int
    public let startDistanceMeters: Double
    public let endDistanceMeters: Double

    public var distanceMeters: Double {
        max(0.0, endDistanceMeters - startDistanceMeters)
    }

    public init(
        id: UUID = UUID(),
        segmentIndex: Int = 0,
        startPointIndex: Int,
        endPointIndex: Int,
        startDistanceMeters: Double = 0.0,
        endDistanceMeters: Double = 0.0
    ) {
        self.id = id
        self.segmentIndex = segmentIndex
        self.startPointIndex = startPointIndex
        self.endPointIndex = endPointIndex
        self.startDistanceMeters = startDistanceMeters
        self.endDistanceMeters = endDistanceMeters
    }

    public init(
        segmentIndex: Int,
        startPointIndex: Int,
        endPointIndex: Int,
        distanceMeters: Double
    ) {
        self.id = UUID()
        self.segmentIndex = segmentIndex
        self.startPointIndex = startPointIndex
        self.endPointIndex = endPointIndex
        self.startDistanceMeters = 0.0
        self.endDistanceMeters = distanceMeters
    }
}
