import Foundation
import XCTest
@testable import UltraNav

final class DegradedOperationIntegrationTests: XCTestCase {
    @MainActor
    func testUnexpectedSensorDisconnectKeepsRideActive() async throws {
        let harness = UltraNavIntegrationHarness()
        await harness.start()

        try await harness.prepareRideSuccessfully()
        try await harness.startRideSuccessfully()
        assertRideActive(harness.container.engines.ride.currentSnapshot)

        // Send sensor disconnect event
        harness.sensors.send(.connectionStateChanged(sensor: TestIDs.heartRateSensor, state: .disconnected))

        // Ride should remain active in degraded state
        assertRideActive(harness.container.engines.ride.currentSnapshot)

        // Reconnect
        harness.sensors.send(.connectionStateChanged(sensor: TestIDs.heartRateSensor, state: .connected))
        assertRideActive(harness.container.engines.ride.currentSnapshot)

        await harness.shutdown()
    }

    @MainActor
    func testRouteWithoutElevationLeavesClimbEngineUnavailable() async throws {
        let harness = UltraNavIntegrationHarness()
        await harness.start()

        try await harness.prepareRideSuccessfully()
        try await harness.startRideSuccessfully()

        let flatRoute = RouteFixture.straightRoute()
        try await harness.loadAndStartRoute(flatRoute)

        let climbSnap = harness.container.engines.climb.currentSnapshot
        XCTAssertFalse(climbSnap.hasActiveClimb)
        XCTAssertEqual(climbSnap.totalClimbsCount, 0)

        await harness.shutdown()
    }
}
