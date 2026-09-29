import Foundation

/// Protocol for generating deterministic RouteID values from coordinate geometry.
public protocol RouteIdentityCreating: Sendable {
    func makeRouteID(points: [Coordinate], segmentBreaks: [Int]) -> RouteID
}
