import XCTest
@testable import UltraNav

@MainActor
final class MetricsViewModelTests: XCTestCase {
    func testMetricsViewModelMapsTilesFromSnapshots() async {
        let clock = TestClock()
        let metrics = MetricsEngine(clock: clock)
        let fakeLocation = FakeLocationProvider()
        let fakeWorkout = FakeWorkoutProvider()
        let fakeSensors = FakeSensorProvider()

        let ride = RideEngine(location: fakeLocation, workout: fakeWorkout, sensors: fakeSensors, clock: clock)

        let viewModel = MetricsViewModel(
            metricsEngine: metrics,
            rideEngine: ride,
            preferences: .metric
        )

        XCTAssertFalse(viewModel.state.isRecording)
        XCTAssertEqual(viewModel.state.tile(for: .speed)?.value.primaryText, "--")

        await metrics.send(.start(at: nil))

        // Ingest speed observation
        let date = clock.now
        metrics.consume(location: LocationSample(
            coordinate: Coordinate(latitude: 37.0, longitude: -122.0),
            altitudeMeters: 100,
            horizontalAccuracyMeters: 5,
            verticalAccuracyMeters: 5,
            speedMetersPerSecond: 10.0, // 36 km/h
            courseDegrees: 90,
            timestamp: date
        ))

        try? await Task.sleep(nanoseconds: 50_000_000)

        let speedTile = viewModel.state.tile(for: .speed)
        XCTAssertEqual(speedTile?.value.primaryText, "36.0")
        XCTAssertEqual(speedTile?.value.unitText, "km/h")
        XCTAssertEqual(speedTile?.value.availability, .available)

        // Change preferences to imperial
        viewModel.updatePreferences(.imperial)
        let imperialSpeedTile = viewModel.state.tile(for: .speed)
        XCTAssertEqual(imperialSpeedTile?.value.primaryText, "22.4")
        XCTAssertEqual(imperialSpeedTile?.value.unitText, "mph")
    }
}
