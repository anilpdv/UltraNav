import XCTest
@testable import UltraNav

final class RideModelTests: XCTestCase {
    func testInitialSnapshotRepresentsIdleRide() {
        let snapshot = RideSnapshot.initial

        XCTAssertEqual(snapshot.state, .idle)
        XCTAssertEqual(snapshot.elapsedTimeSeconds, 0)
        XCTAssertEqual(snapshot.movingTimeSeconds, 0)
        XCTAssertEqual(snapshot.metrics, .empty)
    }

    func testEmptyMetricsUseZeroDistanceAndNoLiveValues() {
        let metrics = RideMetrics.empty

        XCTAssertEqual(metrics.distanceMeters, 0)
        XCTAssertNil(metrics.currentSpeedMetersPerSecond)
        XCTAssertNil(metrics.heartRateBeatsPerMinute)
        XCTAssertNil(metrics.cadenceRevolutionsPerMinute)
        XCTAssertNil(metrics.powerWatts)
        XCTAssertNil(metrics.altitudeMeters)
    }
}
