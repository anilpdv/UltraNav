import Foundation

struct Route: Identifiable, Equatable, Sendable {
    typealias ID = UUID

    let id: ID
    let metadata: RouteMetadata
    let points: [RoutePoint]

    /// Total normalized route distance in meters.
    let totalDistanceMeters: Double

    init(
        id: ID = UUID(),
        metadata: RouteMetadata,
        points: [RoutePoint],
        totalDistanceMeters: Double
    ) {
        self.id = id
        self.metadata = metadata
        self.points = points
        self.totalDistanceMeters = totalDistanceMeters
    }
}
