import Foundation
import XCTest
@testable import UltraNav

final class RecoveryIntegrationTests: XCTestCase {
    @MainActor
    func testLocationFailureAfterWorkoutStartTriggersRollback() async throws {
        let harness = UltraNavIntegrationHarness()
        await harness.start()

        await harness.authorizeAllServices()

        // Configure location start updates to fail
        await harness.location.setStartFailure(.updateFailed)

        // Attempting to start ride should fail and stay out of active state
        await harness.container.coordinators.rideLifecycle.start()

        // Verify ride state is not active
        let snap = harness.container.engines.ride.currentSnapshot
        XCTAssertNotEqual(snap.state, .active)

        await harness.shutdown()
    }
}
