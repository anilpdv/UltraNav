import XCTest
@testable import UltraNav

@MainActor
final class RideEngineTests: XCTestCase {
    private var fakeLocation: FakeLocationService!
    private var fakeWorkout: FakeWorkoutService!
    private var fakeSensor: FakeSensorService!
    private var testClock: TestClock!
    private var rideEngine: RideEngine!

    override func setUp() async throws {
        try await super.setUp()
        fakeLocation = FakeLocationService()
        fakeWorkout = FakeWorkoutService()
        fakeSensor = FakeSensorService()
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
        XCTAssertTrue(fakeLocation.isUpdating)
        XCTAssertTrue(fakeSensor.isScanning)
        XCTAssertTrue(fakeWorkout.startCalled)
        XCTAssertTrue(fakeWorkout.isSessionActive)
        XCTAssertEqual(rideEngine.rideSnapshot.state, .active)
    }

    func testPauseAndResumeRide() async throws {
        try await rideEngine.startRide()
        XCTAssertEqual(rideEngine.state, .active)

        rideEngine.pauseRide()
        XCTAssertEqual(rideEngine.state, .paused)
        XCTAssertTrue(fakeWorkout.pauseCalled)
        XCTAssertEqual(rideEngine.rideSnapshot.state, .paused)

        rideEngine.resumeRide()
        XCTAssertEqual(rideEngine.state, .active)
        XCTAssertTrue(fakeWorkout.resumeCalled)
        XCTAssertEqual(rideEngine.rideSnapshot.state, .active)
    }

    func testFinishRideTransitionsToCompletedAndStopsHardware() async throws {
        try await rideEngine.startRide()
        XCTAssertEqual(rideEngine.state, .active)

        try await rideEngine.finishRide()

        XCTAssertEqual(rideEngine.state, .completed)
        XCTAssertFalse(fakeLocation.isUpdating)
        XCTAssertFalse(fakeSensor.isScanning)
        XCTAssertTrue(fakeWorkout.stopCalled)
        XCTAssertEqual(rideEngine.rideSnapshot.state, .completed)
    }

    func testWorkoutAuthDeniedTransitionsToFailedState() async {
        fakeWorkout.authorizationGranted = false

        do {
            try await rideEngine.prepareRide()
            XCTFail("Expected prepareRide to throw")
        } catch {
            XCTAssertEqual(rideEngine.state, .failed(.workoutAuthorizationDenied))
        }
    }

    func testTimerTickUpdatesMetricsAndSnapshots() async throws {
        try await rideEngine.startRide()

        fakeSensor.simulatePower(250)
        fakeSensor.simulateHeartRate(155)
        fakeSensor.simulateCadence(90)
        fakeSensor.simulateSpeed(32.5)

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

        fakeSensor.simulateSpeed(30.0)
        fakeSensor.simulatePower(200)
        fakeSensor.simulateHeartRate(140)

        for _ in 0..<60 {
            rideEngine.tick()
        }

        rideEngine.triggerManualLap()

        XCTAssertEqual(rideEngine.metricsEngine.laps.count, 1)
        let lap = rideEngine.metricsEngine.laps[0]
        XCTAssertEqual(lap.lapNumber, 1)
        XCTAssertEqual(lap.duration, 60)
        XCTAssertEqual(lap.avgPower, 200)
        XCTAssertEqual(lap.avgHeartRate, 140)
    }
}
