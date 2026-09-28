import Foundation

struct RouteSummary: Identifiable,
                     Equatable,
                     Sendable {
    let id: Route.ID
    let name: String
    let totalDistanceMeters: Double
    let pointCount: Int
    let createdAt: Date?
}
