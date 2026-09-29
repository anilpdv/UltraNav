import Foundation
import XCTest

/// Async waiter utility to poll conditions deterministically with safety timeouts.
enum AsyncTestWaiter {
    /// Polls condition until true or timeout expires.
    static func waitFor(
        timeout: Duration = .seconds(2),
        pollInterval: Duration = .milliseconds(10),
        file: StaticString = #filePath,
        line: UInt = #line,
        condition: @escaping @Sendable () async -> Bool
    ) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)

        while clock.now < deadline {
            if await condition() {
                return
            }
            await Task.yield()
            try? await Task.sleep(for: pollInterval)
        }

        XCTFail("Async condition was not satisfied within \(timeout)", file: file, line: line)
    }
}
