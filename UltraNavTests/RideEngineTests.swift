import XCTest
@testable import UltraNav

@MainActor
final class RideEngineTests: XCTestCase {
    private var fakeLocation: FakeLocationProvider!
    private var fakeWorkout: FakeWorkoutProvider!
    private var fakeSensor: FakeSensorProvider!
    private var testClock: TestClock!
    private var rideEngine: RideEngine!

    override func setUp() async throws {
        try await super.setUp()
        fakeLocation = FakeLocationProvider()
        fakeWorkout = FakeWorkoutProvider()
        fakeSensor = FakeSensorProvider()
        testClock = TestClock()

        rideEngine = RideEngine(
            locationService: fakeLocation,
            workoutService: fakeWorkout,
            sensorService: fakeSensor,
            clock: testClock
        )
    }

    func testStartRideTransitionsToActiveAndStartsHardware() async throws {
        XCTAssertEqual(rideEngine.state, .idle)

        try await rideEngine.startRide()

        XCTAssertEqual(rideEngine.state, .active)
        let startCalls = await fakeLocation.startUpdatesCallCount
        let scanCalls = await fakeSensor.startScanningCallCount
        let startDates = await fakeWorkout.startDates
        XCTAssertEqual(startCalls, 1)
        XCTAssertEqual(scanCalls, 1)
        XCTAssertEqual(startDates.count, 1)
        XCTAssertEqual(rideEngine.rideSnapshot.state, .active)
    }

    func testPauseAndResumeRide() async throws {
        try await rideEngine.startRide()
        XCTAssertEqual(rideEngine.state, .active)

        rideEngine.pauseRide()
        XCTAssertEqual(rideEngine.state, .paused)
        XCTAssertEqual(rideEngine.rideSnapshot.state, .paused)

        rideEngine.resumeRide()
        XCTAssertEqual(rideEngine.state, .active)
        XCTAssertEqual(rideEngine.rideSnapshot.state, .active)
    }

    func testFinishRideTransitionsToCompletedAndStopsHardware() async throws {
        try await rideEngine.startRide()
        XCTAssertEqual(rideEngine.state, .active)

        try await rideEngine.finishRide()

        XCTAssertEqual(rideEngine.state, .completed)
        let stopLocationCalls = await fakeLocation.stopUpdatesCallCount
        let stopScanCalls = await fakeSensor.stopScanningCallCount
        let finishDates = await fakeWorkout.finishDates
        XCTAssertEqual(stopLocationCalls, 1)
        XCTAssertEqual(stopScanCalls, 1)
        XCTAssertEqual(finishDates.count, 1)
        XCTAssertEqual(rideEngine.rideSnapshot.state, .completed)
    }

    func testWorkoutAuthDeniedTransitionsToFailedState() async {
        await fakeWorkout.setAuthorizationFailure(.authorizationDenied)

        do {
            try await rideEngine.prepareRide()
            XCTFail("Expected prepareRide to throw")
        } catch {
            XCTAssertEqual(rideEngine.state, .failed(failure: .workoutAuthorizationDenied, recovery: .returnToIdle))
        }
    }

    func testTimerTickUpdatesMetricsAndSnapshots() async throws {
        try await rideEngine.startRide()

        await fakeSensor.send(.sampleReceived(
            sensor: SensorIdentifier(rawValue: "power-01"),
            sample: .power(watts: 250, timestamp: Date())
        ))
        await fakeSensor.send(.sampleReceived(
            sensor: SensorIdentifier(rawValue: "hr-01"),
            sample: .heartRate(beatsPerMinute: 155, timestamp: Date())
        ))
        await fakeSensor.send(.sampleReceived(
            sensor: SensorIdentifier(rawValue: "cad-01"),
            sample: .cadence(revolutionsPerMinute: 90, timestamp: Date())
        ))
        await fakeSensor.send(.sampleReceived(
            sensor: SensorIdentifier(rawValue: "spd-01"),
            sample: .speed(metersPerSecond: 32.5 / 3.6, timestamp: Date())
        ))

        await Task.yield()

        testClock.advance(by: 10)
        for _ in 0..<10 {
            rideEngine.tick()
        }

        let snapshot = rideEngine.rideSnapshot
        XCTAssertEqual(snapshot.elapsedTimeSeconds, 10)
        XCTAssertEqual(snapshot.metrics.powerWatts, 250)
        XCTAssertEqual(snapshot.metrics.heartRateBeatsPerMinute, 155)
        XCTAssertEqual(snapshot.metrics.cadenceRevolutionsPerMinute, 90)
        XCTAssertEqual(snapshot.metrics.currentSpeedMetersPerSecond, 32.5 / 3.6)
    }

    func testManualLapTriggerCreatesLapRecord() async throws {
        try await rideEngine.startRide()

        for _ in 0..<60 {
            rideEngine.tick()
        }

        rideEngine.triggerManualLap()

        XCTAssertEqual(rideEngine.metricsEngine.laps.count, 1)
        let lap = rideEngine.metricsEngine.laps[0]
        XCTAssertEqual(lap.lapNumber, 1)
        XCTAssertEqual(lap.duration, 60)
    }
}
