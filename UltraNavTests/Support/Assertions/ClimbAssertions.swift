import Foundation
import XCTest
@testable import UltraNav

/// Focused assertions for ClimbEngine snapshots.
func assertClimbingActive(
    _ snapshot: ClimbSnapshot,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertTrue(snapshot.hasActiveClimb, "Expected hasActiveClimb to be true", file: file, line: line)
    XCTAssertNotNil(snapshot.activeClimb, "Expected activeClimb to be non-nil", file: file, line: line)
    XCTAssertNotNil(snapshot.activeClimbProgress, "Expected activeClimbProgress to be non-nil", file: file, line: line)
}

func assertClimbingInactive(
    _ snapshot: ClimbSnapshot,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertFalse(snapshot.hasActiveClimb, "Expected hasActiveClimb to be false", file: file, line: line)
    XCTAssertNil(snapshot.activeClimb, "Expected activeClimb to be nil", file: file, line: line)
}
