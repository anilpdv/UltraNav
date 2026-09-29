import Testing
import Foundation
@testable import UltraNav

@MainActor
struct NavigationEngineFailureTests {
    @Test
    func testInvalidRouteSetsFailedState() async {
        let harness = NavigationEngineHarness()
        let invalidRoute = NavigationRouteFactory.createRoute(
            points: [RoutePoint(coordinate: Coordinate(latitude: 37.7749, longitude: -122.4194), elevationMeters: nil, timestamp: nil, cumulativeDistanceMeters: 0)],
            totalDistanceMeters: 0
        )

        await harness.engine.send(.useRoute(invalidRoute))

        #expect(harness.engine.currentSnapshot.state == .failed(failure: .invalidRoute, recovery: .retryLoading))
        #expect(harness.engine.currentSnapshot.activeFailure == .invalidRoute)
    }

    @Test
    func testRecoveryFromFailedStateReturnsToLoading() async {
        let harness = NavigationEngineHarness()
        let invalidRoute = NavigationRouteFactory.createRoute(
            points: [RoutePoint(coordinate: Coordinate(latitude: 37.7749, longitude: -122.4194), elevationMeters: nil, timestamp: nil, cumulativeDistanceMeters: 0)],
            totalDistanceMeters: 0
        )

        await harness.engine.send(.useRoute(invalidRoute))
        #expect(harness.engine.currentSnapshot.state == .failed(failure: .invalidRoute, recovery: .retryLoading))

        await harness.engine.send(.recover)
        #expect(harness.engine.currentSnapshot.state == .loading)
        #expect(harness.engine.currentSnapshot.activeFailure == nil)
    }
}
