import XCTest
@testable import UltraNav

@MainActor
final class RideEngineIntegrationTests: XCTestCase {
    func testFullOutdoorRideLifecycle() async throws {
        let startTime = Date(timeIntervalSince1970: 1_700_000_000)
        let harness = RideEngineHarness.make(now: startTime)

        // 1. Prepare
        await harness.authorizeAll()
        await harness.engine.send(.prepare)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .ready)
        XCTAssertEqual(harness.engine.locationStatus, .ready)
        XCTAssertEqual(harness.engine.workoutStatus, .ready)

        // 2. Start
        await harness.engine.send(.start)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .active)
        XCTAssertEqual(harness.engine.currentSnapshot.startedAt, startTime)

        // 3. Telemetry Stream
        harness.clock.advance(by: 1200) // 20 min in

        let locSample = LocationSampleFactory.makeSample(altitude: 120.0, speed: 10.5)
        harness.location.send(.locationReceived(locSample))

        let hrSensor = SensorIdentifier(rawValue: "hr-strap")
        harness.sensors.send(.sampleReceived(sensor: hrSensor, sample: .heartRate(beatsPerMinute: 155, timestamp: harness.clock.now)))

        let powerSensor = SensorIdentifier(rawValue: "power-pedals")
        harness.sensors.send(.sampleReceived(sensor: powerSensor, sample: .power(watts: 275, timestamp: harness.clock.now)))

        harness.workout.send(
            .metricReceived(
                .cyclingDistance(
                    meters: 6000.0,
                    timestamp: harness.clock.now
                )
            )
        )

        try? await Task.sleep(nanoseconds: 20_000_000)

        var snapshot = harness.engine.currentSnapshot
        XCTAssertEqual(snapshot.metrics.currentSpeedMetersPerSecond, 10.5)
        XCTAssertEqual(snapshot.metrics.heartRateBeatsPerMinute, 155)
        XCTAssertEqual(snapshot.metrics.powerWatts, 275)
        XCTAssertEqual(snapshot.metrics.distanceMeters, 6000.0)
        XCTAssertEqual(snapshot.elapsedTimeSeconds, 1200)
        XCTAssertEqual(snapshot.movingTimeSeconds, 1200)

        // 4. Pause for traffic
        await harness.engine.send(.pause)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .paused)

        harness.clock.advance(by: 180) // 3 min pause

        // 5. Resume
        await harness.engine.send(.resume)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .active)

        harness.clock.advance(by: 1800) // 30 min more

        // 6. Finish
        await harness.engine.send(.finish)

        snapshot = harness.engine.currentSnapshot
        XCTAssertEqual(snapshot.state, .completed)
        XCTAssertEqual(snapshot.elapsedTimeSeconds, 3180) // 1200 + 180 + 1800
        XCTAssertEqual(snapshot.movingTimeSeconds, 3000)  // 1200 + 1800
        XCTAssertEqual(snapshot.metrics.distanceMeters, 6000.0)
    }
}
