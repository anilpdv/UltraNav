import Testing
import Foundation
@testable import UltraNav

@MainActor
struct NavigationEngineDirectLifecycleTests {
    @Test
    func testNavigationEngineProjections() async {
        let navEngine = NavigationEngine()

        #expect(navEngine.currentSnapshot.state == .inactive)
        #expect(navEngine.currentSnapshot.offRouteStatus == .unknown)
        #expect(navEngine.currentSnapshot.routeID == nil)
        #expect(navEngine.currentSnapshot.routeProgress == 0.0)

        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5)
        await navEngine.send(.useRoute(route))

        #expect(navEngine.currentSnapshot.routeID == route.id)
        #expect(navEngine.currentSnapshot.distanceRemainingMeters == route.totalDistanceMeters)

        await navEngine.send(.start)
        #expect(navEngine.currentSnapshot.state == .navigating)

        await navEngine.send(.stop)
        #expect(navEngine.currentSnapshot.state == .ready)

        await navEngine.send(.clearRoute)
        #expect(navEngine.currentSnapshot.state == .inactive)
        #expect(navEngine.currentSnapshot.routeID == nil)
    }
}
