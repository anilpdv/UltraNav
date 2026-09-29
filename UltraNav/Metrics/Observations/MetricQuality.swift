import Foundation

enum MetricQuality: String, Codable, Equatable, Sendable {
    case valid
    case derived
    case estimated
    case uncertain
}
