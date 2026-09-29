import Foundation

enum RideEngineCommand: Equatable, Sendable {
    case prepare
    case start(at: Date? = nil)
    case pause(at: Date? = nil)
    case resume(at: Date? = nil)
    case finish(at: Date? = nil)
    case recover
    case reset

    static let start: RideEngineCommand = .start(at: nil)
    static let pause: RideEngineCommand = .pause(at: nil)
    static let resume: RideEngineCommand = .resume(at: nil)
    static let finish: RideEngineCommand = .finish(at: nil)
}
