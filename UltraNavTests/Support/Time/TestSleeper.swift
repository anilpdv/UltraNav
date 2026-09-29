import Foundation

/// Fast-forwardable test sleeper that avoids real wall-clock delays in async tests.
final class TestSleeper: @unchecked Sendable {
    private let lock = NSLock()
    private var isInstant = true
    private(set) var sleepCalls: [Duration] = []

    init(instant: Bool = true) {
        self.isInstant = instant
    }

    func setInstant(_ instant: Bool) {
        lock.withLock {
            self.isInstant = instant
        }
    }

    func sleep(for duration: Duration) async throws {
        lock.withLock {
            sleepCalls.append(duration)
        }

        let instant = lock.withLock { isInstant }
        if !instant {
            try await Task.sleep(for: duration)
        } else {
            await Task.yield()
        }
    }
}
