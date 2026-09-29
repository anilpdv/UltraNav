import Testing
import Foundation
@testable import UltraNav

@MainActor
struct NavigationEngineRouteLoadingTests {
    @Test
    func testInitialStateIsInactive() {
        let harness = NavigationEngineHarness()
        #expect(harness.engine.currentSnapshot.state == .inactive)
        #expect(harness.engine.currentSnapshot.routeID == nil)
        #expect(harness.engine.currentSnapshot.nextCue == nil)
        #expect(harness.engine.currentSnapshot.offRouteStatus == .unknown)
    }

    @Test
    func testUseValidRouteTransitionsToReady() async {
        let harness = NavigationEngineHarness()
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5)
        let cue = NavigationRouteFactory.createCue()
        harness.cueProvider.cues = [cue]

        await harness.engine.send(.useRoute(route))

        #expect(harness.engine.currentSnapshot.state == .ready)
        #expect(harness.engine.currentSnapshot.routeID == route.id)
        #expect(harness.engine.currentSnapshot.distanceRemainingMeters == route.totalDistanceMeters)
    }

    @Test
    func testUseRouteWithInsufficientPointsFails() async {
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
    func testUseRouteWithZeroDistanceFails() async {
        let harness = NavigationEngineHarness()
        let invalidRoute = NavigationRouteFactory.createRoute(
            points: [
                RoutePoint(coordinate: Coordinate(latitude: 37.7749, longitude: -122.4194), elevationMeters: nil, timestamp: nil, cumulativeDistanceMeters: 0),
                RoutePoint(coordinate: Coordinate(latitude: 37.7750, longitude: -122.4194), elevationMeters: nil, timestamp: nil, cumulativeDistanceMeters: 0)
            ],
            totalDistanceMeters: 0
        )

        await harness.engine.send(.useRoute(invalidRoute))

        #expect(harness.engine.currentSnapshot.state == .failed(failure: .invalidRoute, recovery: .retryLoading))
        #expect(harness.engine.currentSnapshot.activeFailure == .invalidRoute)
    }

    @Test
    func testLoadingNewRouteWhenReadyReplacesRoute() async {
        let harness = NavigationEngineHarness()
        let route1 = NavigationRouteFactory.createLinearRoute(pointCount: 3, stepDistanceMeters: 100)
        let route2 = NavigationRouteFactory.createLinearRoute(pointCount: 5, stepDistanceMeters: 200)

        await harness.engine.send(.useRoute(route1))
        #expect(harness.engine.currentSnapshot.routeID == route1.id)

        await harness.engine.send(.useRoute(route2))
        #expect(harness.engine.currentSnapshot.routeID == route2.id)
        #expect(harness.engine.currentSnapshot.distanceRemainingMeters == route2.totalDistanceMeters)
    }
}
