import Foundation
import XCTest

/// Standardized timeout limits and wrapper for asynchronous tests.
enum TestTimeout {
    static let instant: Duration = .milliseconds(100)
    static let short: Duration = .seconds(1)
    static let integration: Duration = .seconds(3)
    static let fullApp: Duration = .seconds(5)

    /// Runs an async operation with a hard safety deadline, failing test if timeout is exceeded.
    static func run<T: Sendable>(
        timeout: Duration = .seconds(3),
        file: StaticString = #filePath,
        line: UInt = #line,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(for: timeout)
                throw TimeoutError()
            }

            guard let result = try await group.next() else {
                XCTFail("Operation failed to produce a result within timeout", file: file, line: line)
                throw TimeoutError()
            }
            group.cancelAll()
            return result
        }
    }

    struct TimeoutError: Error, CustomStringConvertible {
        var description: String { "TestTimeout exceeded safety deadline." }
    }
}
