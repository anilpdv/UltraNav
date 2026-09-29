import Testing
import Foundation
@testable import UltraNav

@MainActor
struct NavigationEngineIntegrationTests {
    @Test
    func testCoordinatorFansOutLocationToBothEngines() async throws {
        let rideHarness = RideEngineHarness.make()
        let navEngine = NavigationEngine()

        let coordinator = RideNavigationCoordinator(
            locationProvider: rideHarness.location,
            rideConsumer: rideHarness.engine,
            navigationEngine: navEngine
        )

        coordinator.start()

        // Load route and start navigation
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5, stepDistanceMeters: 100)
        await navEngine.send(.useRoute(route))
        await navEngine.send(.start)

        // Prepare and Start ride
        await rideHarness.prepareAndStart()

        // Send location sample
        let sample = LocationSampleFactory.makeSample(
            speed: 5.0,
            latitude: 37.7749,
            longitude: -122.4194,
            timestamp: rideHarness.clock.now
        )
        rideHarness.location.send(.locationReceived(sample))

        // Yield for async tasks to process
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(rideHarness.engine.currentSnapshot.metrics.currentSpeedMetersPerSecond == 5.0)
        #expect(navEngine.currentSnapshot.currentLocation?.latitude == sample.coordinate.latitude)

        coordinator.stop()
    }
}
