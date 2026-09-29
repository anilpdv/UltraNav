import Foundation

/// Parsed track segment (<trkseg>) containing raw track points.
public struct GPXParsedSegment: Equatable, Hashable, Sendable {
    public let points: [GPXParsedPoint]

    public init(points: [GPXParsedPoint]) {
        self.points = points
    }
}
