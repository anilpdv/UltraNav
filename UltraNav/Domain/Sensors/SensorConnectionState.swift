import Foundation

enum SensorConnectionState: Equatable, Sendable {
    case unavailable
    case idle
    case scanning
    case connecting
    case connected
    case disconnecting
    case disconnected
    case failed
}
