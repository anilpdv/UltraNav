import Foundation

enum LocationServiceState: Equatable, Sendable {
    case idle
    case starting
    case running
    case stopping
    case failed
}
