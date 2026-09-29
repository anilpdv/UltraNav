import Foundation

/// Utilities and diagnostics for verifying concurrency constraints and actor isolation.
enum ConcurrencyDiagnostics {
    /// Asserts that the current code is running on the main actor in debug builds.
    @inline(__always)
    static func assertMainActor(file: StaticString = #file, line: UInt = #line) {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(.main))
        #endif
    }

    /// Verifies if a given task is currently cancelled.
    @inline(__always)
    static func isTaskCancelled() -> Bool {
        Task.isCancelled
    }
}
