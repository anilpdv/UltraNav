import Foundation
@testable import UltraNav

/// Recorder capturing triggered haptic notifications for test verification.
actor HapticRecorder {
    struct HapticEvent: Equatable, Sendable {
        let pattern: HapticPattern
        let timestamp: Date
    }

    private(set) var events: [HapticEvent] = []

    func record(pattern: HapticPattern, at date: Date = Date()) {
        events.append(HapticEvent(pattern: pattern, timestamp: date))
    }

    var count: Int {
        events.count
    }

    var patterns: [HapticPattern] {
        events.map(\.pattern)
    }

    var latestPattern: HapticPattern? {
        events.last?.pattern
    }

    func clear() {
        events.removeAll()
    }
}
