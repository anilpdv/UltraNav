import Foundation

/// Represents the deterministic projection and match of a location onto a route.
public struct RouteMatch: Equatable, Sendable {
    public let matchedCoordinate: Coordinate
    public let segmentIndex: Int
    public let segmentFraction: Double
    public let distanceAlongRouteMeters: Double
    public let crossTrackDistanceMeters: Double
    public let headingDifferenceDegrees: Double?
    public let confidence: RouteMatchingConfidence

    public init(
        matchedCoordinate: Coordinate,
        segmentIndex: Int,
        segmentFraction: Double = 0,
        distanceAlongRouteMeters: Double,
        crossTrackDistanceMeters: Double,
        headingDifferenceDegrees: Double? = nil,
        confidence: RouteMatchingConfidence = .high
    ) {
        self.matchedCoordinate = matchedCoordinate
        self.segmentIndex = segmentIndex
        self.segmentFraction = segmentFraction
        self.distanceAlongRouteMeters = distanceAlongRouteMeters
        self.crossTrackDistanceMeters = crossTrackDistanceMeters
        self.headingDifferenceDegrees = headingDifferenceDegrees
        self.confidence = confidence
    }
}
