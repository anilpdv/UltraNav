import Foundation
@testable import UltraNav

/// Controllable clock with thread-safe lock protection for deterministic testing.
final class TestClock: ClockProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var currentDate: Date

    init(now: Date = Date(timeIntervalSince1970: 1_704_067_200)) {
        self.currentDate = now
    }

    init(initialTime: Date) {
        self.currentDate = initialTime
    }

    var now: Date {
        lock.withLock {
            currentDate
        }
    }

    var currentTime: Date {
        get {
            lock.withLock { currentDate }
        }
        set {
            lock.withLock { currentDate = newValue }
        }
    }

    func advance(by interval: TimeInterval) {
        lock.withLock {
            currentDate = currentDate.addingTimeInterval(interval)
        }
    }

    func set(_ date: Date) {
        lock.withLock {
            currentDate = date
        }
    }
}
