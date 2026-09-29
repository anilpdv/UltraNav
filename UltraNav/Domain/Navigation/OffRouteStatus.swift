import Foundation

enum OffRouteStatus: String, Codable, Equatable, Sendable {
    case unknown
    case onRoute
    case suspected
    case offRoute
    case rejoining
}
