import Foundation

enum MetricsEngineState: Equatable, Sendable {
    case idle
    case active
    case paused
    case stopped
}
