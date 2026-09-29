import Foundation
import XCTest

/// Asynchronous condition helper that yields cooperative tasks until verified or deadline reached.
func eventually(
    timeout: Duration = .seconds(1),
    pollInterval: Duration = .milliseconds(5),
    message: String = "Condition was not satisfied before timeout",
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

    if !(await condition()) {
        XCTFail(message, file: file, line: line)
    }
}
