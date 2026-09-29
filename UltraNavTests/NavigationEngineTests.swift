import Testing
import Foundation
@testable import UltraNav

@MainActor
struct NavigationEngineLegacyAdapterTests {
    @Test
    func testAdapterProjections() async {
        let navEngine = NavigationEngine()
        let adapter = LegacyNavigationAdapter(navigationEngine: navEngine)

        #expect(!adapter.isNavigating)
        #expect(!adapter.isOffRoute)
        #expect(adapter.routeID == nil)
        #expect(adapter.progress == 0.0)

        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5)
        await adapter.load(route: route)

        #expect(adapter.routeID == route.id)
        #expect(adapter.distanceRemaining == route.totalDistanceMeters)

        await adapter.startNavigation()
        #expect(adapter.isNavigating)

        await adapter.stopNavigation()
        #expect(!adapter.isNavigating)

        await adapter.clearRoute()
        #expect(adapter.routeID == nil)
    }
}
