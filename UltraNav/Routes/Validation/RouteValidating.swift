import Foundation

/// Protocol for validating fully formed canonical domain Route instances.
public protocol RouteValidating: Sendable {
    func validate(route: Route) throws
}

public enum RouteValidationFailure: Error, Equatable, Sendable {
    case emptyPoints
    case insufficientPoints(count: Int, minimum: Int)
    case emptyRouteID
    case emptyRouteName
    case invalidDistance(Double)
    case invalidCoordinate(Coordinate)
    case invalidWaypointCoordinate(Coordinate)
    case invalidSegmentIndices(segmentIndex: Int, start: Int, end: Int, totalPoints: Int)
    case nonMonotonicCumulativeDistances
    case segmentsOverlap
    case boundsDoNotContainAllPoints
}
