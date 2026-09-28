import Foundation
@testable import UltraNav

/// Controllable clock for deterministic time advancing in unit tests.
public final class TestClock: ClockProviding, @unchecked Sendable {
    public var currentTime: Date

    public init(initialTime: Date = Date(timeIntervalSince1970: 1704067200)) { // 2024-01-01 00:00:00 UTC
        self.currentTime = initialTime
    }

    public var now: Date {
        currentTime
    }

    public func advance(by interval: TimeInterval) {
        currentTime = currentTime.addingTimeInterval(interval)
    }
}
