import Foundation

enum SensorConnectionState: Equatable, Sendable {
    case disconnected
    case connecting
    case connected
    case discoveringServices
    case discoveringCharacteristics
    case subscribing
    case ready
    case disconnecting
    case failed
}
