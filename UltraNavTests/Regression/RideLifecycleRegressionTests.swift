import Foundation
import XCTest
@testable import UltraNav

final class RideLifecycleRegressionTests: XCTestCase {
    @MainActor
    func testCompleteLifecycleTransitionsWithoutRaceConditions() async throws {
        let harness = UltraNavIntegrationHarness()
        await harness.start()
        
        try await harness.prepareRideSuccessfully()
        assertRideReady(harness.container.engines.ride.currentSnapshot)
        
        try await harness.startRideSuccessfully()
        assertRideActive(harness.container.engines.ride.currentSnapshot)
        
        try await harness.pauseRideSuccessfully()
        assertRidePaused(harness.container.engines.ride.currentSnapshot)
        
        try await harness.resumeRideSuccessfully()
        assertRideActive(harness.container.engines.ride.currentSnapshot)
        
        try await harness.finishRideSuccessfully()
        assertRideCompleted(harness.container.engines.ride.currentSnapshot)
        
        await harness.shutdown()
    }
}
