import Foundation

enum WorkoutAuthorizationStatus: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
    case unavailable
}
