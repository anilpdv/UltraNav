import Foundation

enum LocationAuthorizationStatus: Equatable, Sendable {
    case notDetermined
    case restricted
    case denied
    case authorized
}
