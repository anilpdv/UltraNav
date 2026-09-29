import Testing
import Foundation
@testable import UltraNav

@MainActor
struct NavigationEngineProgressTests {
    @Test
    func testProgressIncreasesMonotonically() async {
        let harness = NavigationEngineHarness()
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5, stepDistanceMeters: 100)
        await harness.engine.send(.useRoute(route))
        await harness.engine.send(.start)

        // Point 1: 100m
        harness.routeMatcher.stubbedMatch = RouteMatch(
            matchedCoordinate: Coordinate(latitude: 37.7750, longitude: -122.4194),
            segmentIndex: 1,
            segmentFraction: 0.0,
            distanceAlongRouteMeters: 100.0,
            crossTrackDistanceMeters: 0.0
        )
        harness.engine.consume(location: LocationSampleFactory.makeSample(latitude: 37.7750, longitude: -122.4194))
        #expect(harness.engine.currentSnapshot.distanceAlongRouteMeters == 100.0)

        // Point 2: 200m
        harness.routeMatcher.stubbedMatch = RouteMatch(
            matchedCoordinate: Coordinate(latitude: 37.7760, longitude: -122.4194),
            segmentIndex: 2,
            segmentFraction: 0.0,
            distanceAlongRouteMeters: 200.0,
            crossTrackDistanceMeters: 0.0
        )
        harness.engine.consume(location: LocationSampleFactory.makeSample(latitude: 37.7760, longitude: -122.4194))
        #expect(harness.engine.currentSnapshot.distanceAlongRouteMeters == 200.0)
    }

    @Test
    func testProgressClampedToRouteBounds() async {
        let harness = NavigationEngineHarness()
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 3, stepDistanceMeters: 100) // Total: 200m
        await harness.engine.send(.useRoute(route))
        await harness.engine.send(.start)

        // Beyond route distance
        harness.routeMatcher.stubbedMatch = RouteMatch(
            matchedCoordinate: Coordinate(latitude: 37.7780, longitude: -122.4194),
            segmentIndex: 2,
            segmentFraction: 1.0,
            distanceAlongRouteMeters: 250.0,
            crossTrackDistanceMeters: 0.0
        )
        harness.engine.consume(location: LocationSampleFactory.makeSample(latitude: 37.7780, longitude: -122.4194))

        #expect(harness.engine.currentSnapshot.routeProgress == 1.0)
        #expect(harness.engine.currentSnapshot.distanceRemainingMeters == 0.0)
    }
}
