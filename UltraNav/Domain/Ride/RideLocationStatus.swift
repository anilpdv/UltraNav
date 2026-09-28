import Foundation

enum RideLocationStatus: Equatable, Sendable {
    case unavailable
    case preparing
    case ready
    case active
    case failed
}
