import XCTest
@testable import UltraNav

@MainActor
final class RideEngineCleanupTests: XCTestCase {
    func testShutdownCancelsConsumersAndStopsHardware() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        await harness.engine.shutdown()

        let locStopCount = await harness.location.stopUpdatesCallCount
        let sensorStopCount = await harness.sensors.stopScanningCallCount
        XCTAssertEqual(locStopCount, 1)
        XCTAssertEqual(sensorStopCount, 1)
    }

    func testResetFromCompletedRestoresIdleState() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()
        await harness.engine.send(.finish)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .completed)

        await harness.engine.send(.reset)

        XCTAssertEqual(harness.engine.currentSnapshot.state, .idle)
        XCTAssertEqual(harness.engine.locationStatus, .unavailable)
        XCTAssertEqual(harness.engine.workoutStatus, .unavailable)
        XCTAssertEqual(harness.engine.sensorStatus, .empty)
        XCTAssertEqual(harness.engine.currentSnapshot.elapsedTimeSeconds, 0)
        XCTAssertEqual(harness.engine.currentSnapshot.movingTimeSeconds, 0)
    }

    func testResetFromFailedRestoresIdleState() async {
        let harness = RideEngineHarness.make()
        await harness.location.setStubbedAuthorizationStatus(.denied)
        await harness.workout.setStubbedAuthorizationStatus(.authorized)

        await harness.engine.send(.prepare)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .locationPermissionDenied, recovery: .returnToIdle))

        await harness.engine.send(.reset)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .idle)
    }

    func testRepeatedActivationDoesNotDuplicateConsumers() async {
        let harness = RideEngineHarness.make()
        harness.engine.activate()
        harness.engine.activate()
        harness.engine.activate()

        await harness.prepareAndStart()
        XCTAssertEqual(harness.engine.currentSnapshot.state, .active)
    }
}
