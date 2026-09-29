import Testing
import Foundation
@testable import UltraNav

@MainActor
struct NavigationEngineLifecycleTests {
    @Test
    func testStartNavigationWhenReadyTransitionsToNavigating() async {
        let harness = NavigationEngineHarness()
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5)
        await harness.engine.send(.useRoute(route))

        await harness.engine.send(.start)

        #expect(harness.engine.currentSnapshot.state == .navigating)
        #expect(harness.engine.currentSnapshot.offRouteStatus == .unknown)
    }

    @Test
    func testStartWithoutLoadedRouteFails() async {
        let harness = NavigationEngineHarness()

        await harness.engine.send(.start)

        #expect(harness.engine.currentSnapshot.state == .inactive)
        #expect(harness.engine.currentSnapshot.activeFailure == .routeUnavailable)
    }

    @Test
    func testStopNavigationReturnsToReady() async {
        let harness = NavigationEngineHarness()
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5)
        await harness.engine.send(.useRoute(route))
        await harness.engine.send(.start)

        await harness.engine.send(.stop)

        #expect(harness.engine.currentSnapshot.state == .ready)
        #expect(harness.engine.currentSnapshot.routeID == route.id)
    }

    @Test
    func testClearRouteFromReadyTransitionsToInactive() async {
        let harness = NavigationEngineHarness()
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5)
        await harness.engine.send(.useRoute(route))

        await harness.engine.send(.clearRoute)

        #expect(harness.engine.currentSnapshot.state == .inactive)
        #expect(harness.engine.currentSnapshot.routeID == nil)
        #expect(harness.engine.currentSnapshot.nextCue == nil)
    }

    @Test
    func testClearRouteWhileNavigatingStopsAndClears() async {
        let harness = NavigationEngineHarness()
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5)
        await harness.engine.send(.useRoute(route))
        await harness.engine.send(.start)

        await harness.engine.send(.stop)
        await harness.engine.send(.clearRoute)

        #expect(harness.engine.currentSnapshot.state == .inactive)
        #expect(harness.engine.currentSnapshot.routeID == nil)
    }

    @Test
    func testResetReturnsToInitialState() async {
        let harness = NavigationEngineHarness()
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5)
        await harness.engine.send(.useRoute(route))
        await harness.engine.send(.start)

        await harness.engine.send(.reset)

        #expect(harness.engine.currentSnapshot.state == .inactive)
        #expect(harness.engine.currentSnapshot.routeID == nil)
        #expect(harness.engine.currentSnapshot.currentLocation == nil)
    }
}
