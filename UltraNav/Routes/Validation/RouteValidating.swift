import Foundation

/// Protocol for validating fully formed domain Route instances.
public protocol RouteValidating: Sendable {
    func validate(route: Route) throws
}

public enum RouteValidationFailure: Error, Equatable, Sendable {
    case emptyPoints
    case invalidDistance(Double)
    case invalidCoordinate(Coordinate)
    case invalidSegmentIndices(segmentIndex: Int, start: Int, end: Int, totalPoints: Int)
    case nonMonotonicCumulativeDistances
}
