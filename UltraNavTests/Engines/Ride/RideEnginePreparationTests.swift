import XCTest
@testable import UltraNav

@MainActor
final class RideEnginePreparationTests: XCTestCase {
    func testInitialEngineStateIsIdle() {
        let harness = RideEngineHarness.make()
        XCTAssertEqual(harness.engine.currentSnapshot.state, .idle)
        XCTAssertEqual(harness.engine.locationStatus, .unavailable)
        XCTAssertEqual(harness.engine.workoutStatus, .unavailable)
    }

    func testPrepareChangesStateToPreparingAndReadyWhenAuthorized() async {
        let harness = RideEngineHarness.make()
        await harness.authorizeAll()

        await harness.engine.send(.prepare)

        XCTAssertEqual(harness.engine.currentSnapshot.state, .ready)
        XCTAssertEqual(harness.engine.locationStatus, .ready)
        XCTAssertEqual(harness.engine.workoutStatus, .ready)
    }

    func testLocationAuthorizationIsChecked() async {
        let harness = RideEngineHarness.make()
        await harness.location.setStubbedAuthorizationStatus(.notDetermined)
        await harness.workout.setStubbedAuthorizationStatus(.authorized)

        await harness.engine.send(.prepare)

        let reqCount = await harness.location.requestAuthorizationCallCount
        XCTAssertEqual(reqCount, 1)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .locationPermissionRequired, recovery: .returnToIdle))
    }

    func testWorkoutAuthorizationIsCheckedAndPrepared() async {
        let harness = RideEngineHarness.make()
        await harness.location.setStubbedAuthorizationStatus(.authorized)
        await harness.workout.setStubbedAuthorizationStatus(.notDetermined)

        await harness.engine.send(.prepare)

        let authCount = await harness.workout.authorizationCallCount
        let prepCount = await harness.workout.prepareCallCount
        XCTAssertEqual(authCount, 1)
        XCTAssertEqual(prepCount, 1)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .ready)
    }

    func testSensorUnavailableDoesNotFailPreparation() async {
        let harness = RideEngineHarness.make()
        await harness.authorizeAll()
        await harness.sensors.setScanFailure(.bluetoothUnavailable(.poweredOff))

        await harness.engine.send(.prepare)

        XCTAssertEqual(harness.engine.currentSnapshot.state, .ready)
    }

    func testLocationDenialFailsPreparation() async {
        let harness = RideEngineHarness.make()
        await harness.location.setStubbedAuthorizationStatus(.denied)
        await harness.workout.setStubbedAuthorizationStatus(.authorized)

        await harness.engine.send(.prepare)

        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .locationPermissionDenied, recovery: .returnToIdle))
    }

    func testHealthKitDenialFailsPreparation() async {
        let harness = RideEngineHarness.make()
        await harness.location.setStubbedAuthorizationStatus(.authorized)
        await harness.workout.setStubbedAuthorizationStatus(.denied)

        await harness.engine.send(.prepare)

        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .workoutAuthorizationDenied, recovery: .returnToIdle))
    }

    func testWorkoutPreparationFailureEntersFailed() async {
        let harness = RideEngineHarness.make()
        await harness.authorizeAll()
        await harness.workout.setPreparationFailure(.preparationFailed)

        await harness.engine.send(.prepare)

        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .workoutPreparationFailed, recovery: .returnToIdle))
    }

    func testPartialPreparationIsRolledBack() async {
        let harness = RideEngineHarness.make()
        await harness.location.setStubbedAuthorizationStatus(.authorized)
        await harness.workout.setStubbedAuthorizationStatus(.authorized)
        await harness.workout.setPreparationFailure(.preparationFailed)

        await harness.engine.send(.prepare)

        let locStopCount = await harness.location.stopUpdatesCallCount
        let workoutResetCount = await harness.workout.resetCallCount
        XCTAssertEqual(locStopCount, 1)
        XCTAssertEqual(workoutResetCount, 1)
        XCTAssertEqual(harness.engine.locationStatus, .unavailable)
        XCTAssertEqual(harness.engine.workoutStatus, .unavailable)
    }

    func testDuplicatePrepareIsRejected() async {
        let harness = RideEngineHarness.make()
        await harness.authorizeAll()

        await harness.engine.send(.prepare)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .ready)

        await harness.engine.send(.prepare)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .ready)
    }

    func testResetAfterPreparationFailureReturnsToIdle() async {
        let harness = RideEngineHarness.make()
        await harness.location.setStubbedAuthorizationStatus(.denied)
        await harness.workout.setStubbedAuthorizationStatus(.authorized)

        await harness.engine.send(.prepare)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .locationPermissionDenied, recovery: .returnToIdle))

        await harness.engine.send(.reset)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .idle)
    }
}
