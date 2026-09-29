import Testing
import Foundation
@testable import UltraNav

@MainActor
struct NavigationEngineResetTests {
    @Test
    func testResetClearsAllInternalState() async {
        let harness = NavigationEngineHarness()
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5)
        await harness.engine.send(.useRoute(route))
        await harness.engine.send(.start)

        harness.engine.consume(location: LocationSampleFactory.makeSample(latitude: 37.7750, longitude: -122.4194))

        await harness.engine.send(.reset)

        #expect(harness.engine.currentSnapshot.state == .inactive)
        #expect(harness.engine.currentSnapshot.routeID == nil)
        #expect(harness.engine.currentSnapshot.nextCue == nil)
        #expect(harness.engine.currentSnapshot.currentLocation == nil)
        #expect(harness.engine.currentSnapshot.distanceAlongRouteMeters == 0.0)
        #expect(harness.engine.currentSnapshot.routeProgress == 0.0)
    }
}
