import XCTest
import CoreLocation
@testable import UltraNav

@MainActor
final class RideDataCoordinatorTests: XCTestCase {

    func testActivationStartsStreamConsumption() async {
        let fakeLocation = FakeLocationProvider()
        let fakeWorkout = FakeWorkoutProvider()
        let fakeSensors = FakeSensorProvider()
        let clock = TestClock()

        let ride = RideEngine(location: fakeLocation, workout: fakeWorkout, sensors: fakeSensors, clock: clock)
        let metrics = MetricsEngine(clock: clock)
        let navigation = NavigationEngine()

        let coordinator = RideDataCoordinator(
            location: fakeLocation,
            workout: fakeWorkout,
            sensors: fakeSensors,
            rideLocationConsumer: ride,
            rideWorkoutConsumer: ride,
            rideSensorConsumer: ride,
            metricsEngine: metrics,
            navigationEngine: navigation
        )

        XCTAssertFalse(coordinator.isActive)
        coordinator.activate()
        XCTAssertTrue(coordinator.isActive)

        // Repeated activation is a no-op
        coordinator.activate()
        XCTAssertTrue(coordinator.isActive)

        coordinator.shutdown()
        XCTAssertFalse(coordinator.isActive)
    }

    func testLocationEventFanOutToEngines() async {
        let fakeLocation = FakeLocationProvider()
        let fakeWorkout = FakeWorkoutProvider()
        let fakeSensors = FakeSensorProvider()
        let clock = TestClock()

        let ride = RideEngine(location: fakeLocation, workout: fakeWorkout, sensors: fakeSensors, clock: clock)
        let metrics = MetricsEngine(clock: clock)
        let navigation = NavigationEngine()

        let gpsProcessor = GPSProcessor()
        let coordinator = RideDataCoordinator(
            location: fakeLocation,
            workout: fakeWorkout,
            sensors: fakeSensors,
            rideLocationConsumer: ride,
            rideWorkoutConsumer: ride,
            rideSensorConsumer: ride,
            metricsEngine: metrics,
            navigationEngine: navigation,
            gpsProcessor: gpsProcessor,
            clock: clock
        )

        coordinator.activate()
        await gpsProcessor.send(.start(at: clock.now))
        await metrics.send(.start(at: clock.now))

        let sample = LocationSampleFactory.make(
            altitudeMeters: 100,
            horizontalAccuracyMeters: 5,
            speedMetersPerSecond: 10.0,
            courseDegrees: 90,
            timestamp: clock.now
        )

        fakeLocation.send(.locationReceived(sample))
        // Yield to allow async task to process
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Verify metrics received location
        XCTAssertEqual(metrics.currentSnapshot.speed?.value, 10.0)
        XCTAssertEqual(metrics.currentSnapshot.altitude?.value, 100.0)

        coordinator.shutdown()
    }

    func testWorkoutEventFanOutToEngines() async {
        let fakeLocation = FakeLocationProvider()
        let fakeWorkout = FakeWorkoutProvider()
        let fakeSensors = FakeSensorProvider()
        let clock = TestClock()

        let ride = RideEngine(location: fakeLocation, workout: fakeWorkout, sensors: fakeSensors, clock: clock)
        let metrics = MetricsEngine(clock: clock)
        let navigation = NavigationEngine()

        let coordinator = RideDataCoordinator(
            location: fakeLocation,
            workout: fakeWorkout,
            sensors: fakeSensors,
            rideLocationConsumer: ride,
            rideWorkoutConsumer: ride,
            rideSensorConsumer: ride,
            metricsEngine: metrics,
            navigationEngine: navigation
        )

        coordinator.activate()
        await metrics.send(.start(at: clock.now))

        fakeWorkout.send(.heartRateReceived(beatsPerMinute: 155, timestamp: clock.now))
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(metrics.currentSnapshot.heartRate?.value, 155)

        coordinator.shutdown()
    }

    func testSensorEventFanOutToEngines() async {
        let fakeLocation = FakeLocationProvider()
        let fakeWorkout = FakeWorkoutProvider()
        let fakeSensors = FakeSensorProvider()
        let clock = TestClock()

        let ride = RideEngine(location: fakeLocation, workout: fakeWorkout, sensors: fakeSensors, clock: clock)
        let metrics = MetricsEngine(clock: clock)
        let navigation = NavigationEngine()

        let coordinator = RideDataCoordinator(
            location: fakeLocation,
            workout: fakeWorkout,
            sensors: fakeSensors,
            rideLocationConsumer: ride,
            rideWorkoutConsumer: ride,
            rideSensorConsumer: ride,
            metricsEngine: metrics,
            navigationEngine: navigation
        )

        coordinator.activate()
        await metrics.send(.start(at: clock.now))

        let sensorID = SensorIdentifier(rawValue: "power-meter-1")
        fakeSensors.send(.sampleReceived(sensor: sensorID, sample: .power(watts: 250, timestamp: clock.now)))
        fakeSensors.send(.sampleReceived(sensor: sensorID, sample: .cadence(revolutionsPerMinute: 90, timestamp: clock.now)))
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(metrics.currentSnapshot.power?.value, 250)
        XCTAssertEqual(metrics.currentSnapshot.cadence?.value, 90)

        coordinator.shutdown()
    }
}
