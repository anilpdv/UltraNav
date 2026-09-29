import Foundation
import XCTest
@testable import UltraNav

/// Focused assertions for MetricsEngine snapshots.
func assertMetricsSpeed(
    _ snapshot: MetricsSnapshot,
    expected: Double,
    accuracy: Double = 0.01,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let speed = snapshot.speed?.value else {
        XCTFail("Expected speed value in snapshot, but speed was nil", file: file, line: line)
        return
    }
    XCTAssertEqual(speed, expected, accuracy: accuracy, "Speed \(speed) did not match expected \(expected)", file: file, line: line)
}

func assertMetricsHeartRate(
    _ snapshot: MetricsSnapshot,
    expected: Int,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let hr = snapshot.heartRate?.value else {
        XCTFail("Expected heart rate value in snapshot, but heartRate was nil", file: file, line: line)
        return
    }
    XCTAssertEqual(hr, expected, "HeartRate \(hr) did not match expected \(expected)", file: file, line: line)
}

func assertMetricsPower(
    _ snapshot: MetricsSnapshot,
    expected: Int,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let p = snapshot.power?.value else {
        XCTFail("Expected power value in snapshot, but power was nil", file: file, line: line)
        return
    }
    XCTAssertEqual(p, expected, "Power \(p) did not match expected \(expected)", file: file, line: line)
}
