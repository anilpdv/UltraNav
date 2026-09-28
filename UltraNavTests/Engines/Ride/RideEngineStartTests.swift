import XCTest
@testable import UltraNav

@MainActor
final class RideEngineStartTests: XCTestCase {
    func testStartRequiresReadyState() async {
        let harness = RideEngineHarness.make()
        // Starts from idle
        await harness.engine.send(.start)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .idle)
    }

    func testOneSharedStartDateIsCaptured() async {
        let startDate = Date(timeIntervalSince1970: 1_700_000_100)
        let harness = RideEngineHarness.make(now: startDate)

        await harness.prepareAndStart()

        let workoutDates = await harness.workout.startDates
        XCTAssertEqual(workoutDates.first, startDate)
        XCTAssertEqual(harness.engine.currentSnapshot.startedAt, startDate)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .active)
    }

    func testWorkoutStarts() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        let workoutDates = await harness.workout.startDates
        XCTAssertEqual(workoutDates.count, 1)
    }

    func testLocationUpdatesStart() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        let locCount = await harness.location.startUpdatesCallCount
        XCTAssertEqual(locCount, 1)
    }

    func testSuccessfulStartEntersActive() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        XCTAssertEqual(harness.engine.currentSnapshot.state, .active)
        XCTAssertEqual(harness.engine.locationStatus, .active)
        XCTAssertEqual(harness.engine.workoutStatus, .active)
    }

    func testTimingStartsOnlyAfterMandatoryStartupSucceeds() async {
        let startTime = Date(timeIntervalSince1970: 1_700_000_000)
        let harness = RideEngineHarness.make(now: startTime)

        await harness.prepareSuccessfully()
        XCTAssertEqual(harness.engine.currentSnapshot.elapsedTimeSeconds, 0)
        XCTAssertEqual(harness.engine.currentSnapshot.movingTimeSeconds, 0)

        await harness.engine.send(.start)
        harness.clock.advance(by: 50)

        XCTAssertEqual(harness.engine.currentSnapshot.elapsedTimeSeconds, 50)
        XCTAssertEqual(harness.engine.currentSnapshot.movingTimeSeconds, 50)
    }

    func testWorkoutStartFailurePreventsLocationStart() async {
        let harness = RideEngineHarness.make()
        await harness.prepareSuccessfully()
        await harness.workout.setStartFailure(.startFailed)

        await harness.engine.send(.start)

        let locCount = await harness.location.startUpdatesCallCount
        XCTAssertEqual(locCount, 0)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .workoutStartFailed, recovery: .returnToReady))
    }

    func testLocationStartFailureRollsBackWorkout() async {
        let harness = RideEngineHarness.make()
        await harness.prepareSuccessfully()
        await harness.location.setStartFailure(.servicesDisabled)

        await harness.engine.send(.start)

        let cancelCount = await harness.workout.cancelCallCount
        let locStopCount = await harness.location.stopUpdatesCallCount
        XCTAssertEqual(cancelCount, 1)
        XCTAssertEqual(locStopCount, 1)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .locationUnavailable, recovery: .returnToReady))
    }

    func testDuplicateStartDoesNotStartDependenciesTwice() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        await harness.engine.send(.start)

        let workoutDates = await harness.workout.startDates
        let locCount = await harness.location.startUpdatesCallCount
        XCTAssertEqual(workoutDates.count, 1)
        XCTAssertEqual(locCount, 1)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .active)
    }

    func testSensorAvailabilityDoesNotBlockStart() async {
        let harness = RideEngineHarness.make()
        await harness.prepareSuccessfully()
        await harness.sensors.setScanFailure(.bluetoothUnavailable(.poweredOff))

        await harness.engine.send(.start)

        XCTAssertEqual(harness.engine.currentSnapshot.state, .active)
    }
}
