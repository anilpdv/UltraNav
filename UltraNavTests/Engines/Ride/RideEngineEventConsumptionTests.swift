import XCTest
@testable import UltraNav

@MainActor
final class RideEngineEventConsumptionTests: XCTestCase {
    func testActiveRideAcceptsLocationSampleAndUpdatesSpeedAltitude() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        let sample = LocationSampleFactory.makeSample(speed: 12.5, altitude: 350.0)
        harness.location.send(.locationReceived(sample))

        await Task.yield()

        XCTAssertEqual(harness.engine.currentSnapshot.metrics.currentSpeedMetersPerSecond, 12.5)
        XCTAssertEqual(harness.engine.currentSnapshot.metrics.altitudeMeters, 350.0)
    }

    func testIdleEngineIgnoresRideLocationMetrics() async {
        let harness = RideEngineHarness.make()
        let sample = LocationSampleFactory.makeSample(speed: 12.5, altitude: 350.0)
        harness.location.send(.locationReceived(sample))

        await Task.yield()

        XCTAssertNil(harness.engine.currentSnapshot.metrics.currentSpeedMetersPerSecond)
    }

    func testPausedRideIgnoresRideMetricUpdates() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()
        await harness.engine.send(.pause)

        let sample = LocationSampleFactory.makeSample(speed: 15.0, altitude: 400.0)
        harness.location.send(.locationReceived(sample))

        await Task.yield()

        XCTAssertNil(harness.engine.currentSnapshot.metrics.currentSpeedMetersPerSecond)
    }

    func testHeartRateObservationUpdatesSnapshot() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        harness.workout.send(
            .metricReceived(
                .heartRate(
                    beatsPerMinute: 152.4,
                    timestamp: harness.clock.now
                )
            )
        )

        await Task.yield()

        XCTAssertEqual(harness.engine.currentSnapshot.metrics.heartRateBeatsPerMinute, 152)
    }

    func testCumulativeHealthKitDistanceUpdatesDistance() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        harness.workout.send(
            .metricReceived(
                .cyclingDistance(
                    meters: 4500.0,
                    timestamp: harness.clock.now
                )
            )
        )

        await Task.yield()

        XCTAssertEqual(harness.engine.currentSnapshot.metrics.distanceMeters, 4500.0)
    }

    func testWorkoutFailureMapsToRideFailure() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        harness.workout.send(.failed(.startFailed))

        await Task.yield()

        XCTAssertTrue(harness.engine.degradations.contains(.workoutMetricsUnavailable))
    }

    func testHRSampleUpdatesSnapshot() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        let sensorID = SensorIdentifier(rawValue: "hr-01")
        harness.sensors.send(.sampleReceived(sensor: sensorID, sample: .heartRate(beatsPerMinute: 165, timestamp: harness.clock.now)))

        await Task.yield()

        XCTAssertEqual(harness.engine.currentSnapshot.metrics.heartRateBeatsPerMinute, 165)
    }

    func testPowerSampleUpdatesSnapshot() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        let sensorID = SensorIdentifier(rawValue: "power-01")
        harness.sensors.send(.sampleReceived(sensor: sensorID, sample: .power(watts: 320, timestamp: harness.clock.now)))

        await Task.yield()

        XCTAssertEqual(harness.engine.currentSnapshot.metrics.powerWatts, 320)
    }

    func testCadenceSampleUpdatesSnapshot() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        let sensorID = SensorIdentifier(rawValue: "cadence-01")
        harness.sensors.send(.sampleReceived(sensor: sensorID, sample: .cadence(revolutionsPerMinute: 92.0, timestamp: harness.clock.now)))

        await Task.yield()

        XCTAssertEqual(harness.engine.currentSnapshot.metrics.cadenceRevolutionsPerMinute, 92.0)
    }

    func testSpeedSampleUpdatesSnapshot() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        let sensorID = SensorIdentifier(rawValue: "speed-01")
        harness.sensors.send(.sampleReceived(sensor: sensorID, sample: .speed(metersPerSecond: 11.2, timestamp: harness.clock.now)))

        await Task.yield()

        XCTAssertEqual(harness.engine.currentSnapshot.metrics.currentSpeedMetersPerSecond, 11.2)
    }

    func testSensorFailureDoesNotFailRide() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        harness.sensors.send(.failed(.disconnectedUnexpectedly(SensorIdentifier(rawValue: "hr-01"))))

        await Task.yield()

        XCTAssertEqual(harness.engine.currentSnapshot.state, .active)
        XCTAssertTrue(harness.engine.degradations.contains(.sensorsUnavailable))
    }

    func testDisconnectionUpdatesSensorStatus() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        let sensorID = SensorIdentifier(rawValue: "sensor-01")
        harness.sensors.send(.connectionStateChanged(sensor: sensorID, state: .ready))
        await Task.yield()

        XCTAssertEqual(harness.engine.sensorStatus.readySensorCount, 1)

        harness.sensors.send(.connectionStateChanged(sensor: sensorID, state: .disconnected))
        await Task.yield()

        XCTAssertEqual(harness.engine.sensorStatus.readySensorCount, 0)
    }
}
