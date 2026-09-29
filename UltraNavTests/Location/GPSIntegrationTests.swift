import XCTest
@testable import UltraNav

final class GPSIntegrationTests: XCTestCase {
    @MainActor
    func testCoordinatorRoutesAcceptedSamplesToMetricsAndNavigation() async {
        let clock = TestClock()
        let fakeLocation = FakeLocationProvider()
        let fakeWorkout = FakeWorkoutProvider()
        let fakeSensors = FakeSensorProvider()

        let rideEngine = RideEngine(location: fakeLocation, workout: fakeWorkout, sensors: fakeSensors, clock: clock)
        let metricsEngine = MetricsEngine(clock: clock)
        let navigationEngine = NavigationEngine(routeStore: FakeRouteStore())
        let gpsProcessor = GPSProcessor()

        let coordinator = RideDataCoordinator(
            location: fakeLocation,
            workout: fakeWorkout,
            sensors: fakeSensors,
            rideLocationConsumer: rideEngine,
            rideWorkoutConsumer: rideEngine,
            rideSensorConsumer: rideEngine,
            metricsEngine: metricsEngine,
            navigationEngine: navigationEngine,
            gpsProcessor: gpsProcessor,
            clock: clock
        )

        coordinator.activate()

        // Start ride engines and GPS processor
        await gpsProcessor.send(.start(at: clock.now))
        await metricsEngine.send(.start(at: clock.now))

        // Send valid location sample
        let sample = LocationSample(
            coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100),
            altitudeMeters: 100.0,
            horizontalAccuracyMeters: 5.0,
            speedMetersPerSecond: 12.0,
            timestamp: clock.now
        )

        fakeLocation.send(.locationReceived(sample))

        // Allow async task to consume
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Metrics snapshot should have received speed from GPS!
        let metricsSnap = metricsEngine.currentSnapshot
        XCTAssertEqual(metricsSnap.speed?.value, 12.0)

        coordinator.shutdown()
    }
}
