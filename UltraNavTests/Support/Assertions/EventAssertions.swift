import Foundation
import XCTest

/// Focused assertions for event sequences and call order.
func XCTAssertEqualEvents<Event: Equatable>(
    _ actual: [Event],
    _ expected: [Event],
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(
        actual,
        expected,
        "Event sequence mismatch. Actual: \(actual), Expected: \(expected)",
        file: file,
        line: line
    )
}
