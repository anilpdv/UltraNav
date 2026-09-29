import Foundation

/// Direction of travel along the route geometry.
enum NavigationTravelDirection: String, Codable, Equatable, Sendable {
    case forward
    case backward
    case stationary
    case unknown
}
