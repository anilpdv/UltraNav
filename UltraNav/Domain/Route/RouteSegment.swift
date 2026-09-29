import Foundation

/// Represents a distinct continuous segment within a route's points array.
public struct RouteSegment: Equatable, Hashable, Codable, Sendable {
    public let segmentIndex: Int
    public let startPointIndex: Int
    public let endPointIndex: Int
    public let distanceMeters: Double

    public init(
        segmentIndex: Int,
        startPointIndex: Int,
        endPointIndex: Int,
        distanceMeters: Double
    ) {
        self.segmentIndex = segmentIndex
        self.startPointIndex = startPointIndex
        self.endPointIndex = endPointIndex
        self.distanceMeters = distanceMeters
    }
}
