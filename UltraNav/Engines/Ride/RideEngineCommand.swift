import Foundation

enum RideEngineCommand: Equatable, Sendable {
    case prepare
    case start
    case pause
    case resume
    case finish
    case recover
    case reset
}
