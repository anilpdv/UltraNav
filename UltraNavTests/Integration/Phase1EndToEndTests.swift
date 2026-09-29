import Foundation
import XCTest
@testable import UltraNav

final class Phase1EndToEndTests: XCTestCase {
    @MainActor
    func testPhase1CompleteSystemEndToEnd() async throws {
        let harness = UltraNavIntegrationHarness()
        await harness.start()
        
        // 1. Prepare and authorize
        try await harness.prepareRideSuccessfully()
        assertRideReady(harness.container.engines.ride.currentSnapshot)
        
        // 2. Load climbing route
        let route = RouteFixture.climbingRoute()
        try await harness.loadAndStartRoute(route)
        
        // 3. Start ride
        try await harness.startRideSuccessfully()
        assertRideActive(harness.container.engines.ride.currentSnapshot)
        
        // 4. Feed GPS along route
        let pt = route.points[2]
        let sample = LocationSample(
            coordinate: pt.coordinate,
            altitudeMeters: pt.elevationMeters,
            horizontalAccuracyMeters: 3.0,
            verticalAccuracyMeters: 3.0,
            speedMetersPerSecond: 8.5,
            courseDegrees: 30.0,
            timestamp: TestDates.rideStart.addingTimeInterval(20)
        )
        harness.location.send(.locationReceived(sample))
        harness.clock.advance(by: 20.0)
        
        // 5. Assert navigation and ride states
        let navSnap = harness.container.engines.navigation.currentSnapshot
        XCTAssertEqual(navSnap.state, .navigating)
        
        // 6. Finish ride
        try await harness.finishRideSuccessfully()
        assertRideCompleted(harness.container.engines.ride.currentSnapshot)
        
        await harness.shutdown()
    }
}
