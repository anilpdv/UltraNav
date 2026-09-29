import Foundation
import XCTest
@testable import UltraNav

/// Utility to assert that registries, operations, and coordinator tasks are cleanly cancelled and deallocated.
enum TaskLeakDetector {
    /// Asserts that a given TaskRegistry has 0 active tasks.
    static func assertNoActiveTasks(
        in registry: TaskRegistry,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(registry.count, 0, "TaskRegistry has remaining uncancelled tasks", file: file, line: line)
    }
}
