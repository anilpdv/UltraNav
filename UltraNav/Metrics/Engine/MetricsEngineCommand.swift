import Foundation

enum MetricsEngineCommand: Equatable, Sendable {
    case start(at: Date? = nil)
    case pause(at: Date? = nil)
    case resume(at: Date? = nil)
    case stop(at: Date? = nil)
    case finish(at: Date? = nil)
    case createManualLap(at: Date? = nil)
    case reset

    static let start: MetricsEngineCommand = .start(at: nil)
    static let pause: MetricsEngineCommand = .pause(at: nil)
    static let resume: MetricsEngineCommand = .resume(at: nil)
    static let stop: MetricsEngineCommand = .stop(at: nil)
    static let finish: MetricsEngineCommand = .finish(at: nil)
}

enum MetricsRecordingState: Equatable, Sendable {
    case idle
    case recording(startedAt: Date)
    case paused(startedAt: Date, pausedAt: Date)
    case finished(startedAt: Date, finishedAt: Date)
}
