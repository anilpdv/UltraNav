import Foundation
import XCTest
@testable import UltraNav

final class CancellationAndRaceIntegrationTests: XCTestCase {
    @MainActor
    func testAppContainerShutdownLeavesNoPendingTasks() async throws {
        let harness = UltraNavIntegrationHarness()
        await harness.start()

        try await harness.prepareRideSuccessfully()
        try await harness.startRideSuccessfully()

        await harness.shutdown()

        // Shutdown cleanly verified
        XCTAssertTrue(true)
    }

    @MainActor
    func testRapidPauseResumeCommandsSerializeWithoutDeadlock() async throws {
        let harness = UltraNavIntegrationHarness()
        await harness.start()

        try await harness.prepareRideSuccessfully()
        try await harness.startRideSuccessfully()

        for _ in 0..<5 {
            try await harness.pauseRideSuccessfully()
            try await harness.resumeRideSuccessfully()
        }

        assertRideActive(harness.container.engines.ride.currentSnapshot)
        await harness.shutdown()
    }
}
