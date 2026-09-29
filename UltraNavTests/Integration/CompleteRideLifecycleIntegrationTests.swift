import Foundation
import XCTest
@testable import UltraNav

final class CompleteRideLifecycleIntegrationTests: XCTestCase {
    @MainActor
    func testCompleteRideLifecycleWithoutRouteOrSensors() async throws {
        let harness = UltraNavIntegrationHarness()
        await harness.start()

        // 1. Prepare
        try await harness.prepareRideSuccessfully()
        assertRideReady(harness.container.engines.ride.currentSnapshot)

        // 2. Start
        try await harness.startRideSuccessfully()
        assertRideActive(harness.container.engines.ride.currentSnapshot)

        // 3. Emit GPS samples
        harness.location.send(.locationReceived(LocationFixture.accurate()))
        harness.clock.advance(by: 5.0)

        // 4. Pause & Resume
        try await harness.pauseRideSuccessfully()
        assertRidePaused(harness.container.engines.ride.currentSnapshot)

        try await harness.resumeRideSuccessfully()
        assertRideActive(harness.container.engines.ride.currentSnapshot)

        // 5. Finish
        try await harness.finishRideSuccessfully()
        assertRideCompleted(harness.container.engines.ride.currentSnapshot)

        await harness.shutdown()
    }

    @MainActor
    func testCompleteRideLifecycleWithRouteNavigationAndClimb() async throws {
        let harness = UltraNavIntegrationHarness()
        await harness.start()

        try await harness.prepareRideSuccessfully()
        try await harness.startRideSuccessfully()

        let climbingRoute = RouteFixture.climbingRoute()
        try await harness.loadAndStartRoute(climbingRoute)

        // Verify navigation and climb engines are engaged
        let navSnap = harness.container.engines.navigation.currentSnapshot
        XCTAssertEqual(navSnap.state, .navigating)

        let climbSnap = harness.container.engines.climb.currentSnapshot
        XCTAssertEqual(climbSnap.totalClimbsCount, 1)

        // Finish ride
        try await harness.finishRideSuccessfully()
        assertRideCompleted(harness.container.engines.ride.currentSnapshot)

        await harness.shutdown()
    }
}
