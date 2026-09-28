import Foundation

enum RideEffect: Equatable, Sendable {
    case prepareDependencies
    case startRide
    case pauseRide
    case resumeRide
    case finishRide
    case resetRide
}
