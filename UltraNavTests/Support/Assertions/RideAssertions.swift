import Foundation
import XCTest
@testable import UltraNav

/// Focused assertions for RideEngine snapshots and states.
func assertRideActive(
    _ snapshot: RideSnapshot,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(snapshot.state, .active, "Expected ride state to be .active, got \(snapshot.state)", file: file, line: line)
    XCTAssertEqual(snapshot.workoutStatus, .active, "Expected workout status to be .active, got \(snapshot.workoutStatus)", file: file, line: line)
    XCTAssertEqual(snapshot.locationStatus, .active, "Expected location status to be .active, got \(snapshot.locationStatus)", file: file, line: line)
}

func assertRidePaused(
    _ snapshot: RideSnapshot,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(snapshot.state, .paused, "Expected ride state to be .paused, got \(snapshot.state)", file: file, line: line)
}

func assertRideReady(
    _ snapshot: RideSnapshot,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(snapshot.state, .ready, "Expected ride state to be .ready, got \(snapshot.state)", file: file, line: line)
}

func assertRideIdle(
    _ snapshot: RideSnapshot,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(snapshot.state, .idle, "Expected ride state to be .idle, got \(snapshot.state)", file: file, line: line)
}

func assertRideCompleted(
    _ snapshot: RideSnapshot,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(snapshot.state, .completed, "Expected ride state to be .completed, got \(snapshot.state)", file: file, line: line)
}
