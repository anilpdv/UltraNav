import XCTest
@testable import UltraNav

@MainActor
final class MetricsEngineTests: XCTestCase {
    private var metricsEngine: MetricsEngine!

    override func setUp() async throws {
        try await super.setUp()
        metricsEngine = MetricsEngine()
    }

    func testTimerTickIncrementsTimeAndComputesAverageSpeed() {
        metricsEngine.isAutoPauseEnabled = false

        // Simulate incremental points summing to ~550m
        for i in 0...10 {
            let lat = 37.3349 + (Double(i) * 0.0005)
            let loc = LocationSample(
                coordinate: Coordinate(latitude: lat, longitude: -122.0090),
                speedMetersPerSecond: 10.0,
                timestamp: Date(timeIntervalSince1970: 1000 + Double(i))
            )
            metricsEngine.update(location: loc)
        }

        for _ in 0..<100 {
            metricsEngine.updateTimerTick()
        }

        XCTAssertEqual(metricsEngine.elapsedTime, 100)
        XCTAssertEqual(metricsEngine.movingTime, 100)
        XCTAssertGreaterThan(metricsEngine.metrics.distanceMeters, 500)
        XCTAssertGreaterThan(metricsEngine.metrics.currentSpeedMetersPerSecond ?? 0, 0)
    }

    func testSensorUpdatesReflectInMetrics() {
        metricsEngine.updateSensors(
            speedMetersPerSecond: 28.4 / 3.6,
            heartRate: 162,
            cadenceRPM: 88,
            powerWatts: 245,
            activeCalories: 350
        )

        let m = metricsEngine.metrics
        XCTAssertEqual(m.currentSpeedMetersPerSecond, 28.4 / 3.6)
        XCTAssertEqual(m.heartRateBeatsPerMinute, 162)
        XCTAssertEqual(m.cadenceRevolutionsPerMinute, 88)
        XCTAssertEqual(m.powerWatts, 245)
        XCTAssertEqual(metricsEngine.activeCalories, 350)
    }

    func testAutoLapDistanceTriggersLapRecord() {
        metricsEngine.autoLapDistanceMeters = 1000.0

        // Push distance past 1000m incrementally (~1200m total)
        for i in 0...20 {
            let lat = 37.3349 + (Double(i) * 0.0006)
            let loc = LocationSample(
                coordinate: Coordinate(latitude: lat, longitude: -122.0090),
                timestamp: Date(timeIntervalSince1970: 1000 + Double(i))
            )
            metricsEngine.update(location: loc)
        }

        metricsEngine.updateTimerTick()

        XCTAssertEqual(metricsEngine.laps.count, 1)
        XCTAssertEqual(metricsEngine.laps[0].lapNumber, 1)
        XCTAssertGreaterThan(metricsEngine.laps[0].distance, 1000)
    }
}
