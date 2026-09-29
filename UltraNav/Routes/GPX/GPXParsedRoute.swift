import Foundation

/// Parsed route (<rte>) containing route points (<rtept>).
public struct GPXParsedRoute: Equatable, Hashable, Sendable {
    public let name: String?
    public let description: String?
    public let points: [GPXParsedPoint]

    public init(
        name: String? = nil,
        description: String? = nil,
        points: [GPXParsedPoint] = []
    ) {
        self.name = name
        self.description = description
        self.points = points
    }
}
