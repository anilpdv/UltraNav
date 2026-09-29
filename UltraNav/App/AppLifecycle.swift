import Foundation

enum AppLifecycleState: String, Equatable, Sendable {
    case created
    case starting
    case running
    case stopping
    case stopped
    case failed
}
