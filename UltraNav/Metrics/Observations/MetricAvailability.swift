import Foundation

enum MetricAvailability: String, Codable, Equatable, Sendable {
    case available
    case stale
    case unavailable
    case invalid
}
