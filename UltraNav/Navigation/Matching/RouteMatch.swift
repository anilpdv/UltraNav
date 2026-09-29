import Foundation

struct RouteMatch: Equatable, Sendable {
    let matchedCoordinate: Coordinate
    let segmentIndex: Int
    let segmentFraction: Double
    let distanceAlongRouteMeters: Double
    let crossTrackDistanceMeters: Double
    let headingDifferenceDegrees: Double?

    init(
        matchedCoordinate: Coordinate,
        segmentIndex: Int,
        segmentFraction: Double = 0,
        distanceAlongRouteMeters: Double,
        crossTrackDistanceMeters: Double,
        headingDifferenceDegrees: Double? = nil
    ) {
        self.matchedCoordinate = matchedCoordinate
        self.segmentIndex = segmentIndex
        self.segmentFraction = segmentFraction
        self.distanceAlongRouteMeters = distanceAlongRouteMeters
        self.crossTrackDistanceMeters = crossTrackDistanceMeters
        self.headingDifferenceDegrees = headingDifferenceDegrees
    }
}
