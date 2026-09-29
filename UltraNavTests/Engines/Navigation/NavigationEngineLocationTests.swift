import Testing
import Foundation
@testable import UltraNav

@MainActor
struct NavigationEngineLocationTests {
    @Test
    func testConsumeLocationWhenInactiveUpdatesLocationOnly() {
        let harness = NavigationEngineHarness()
        let sample = LocationSampleFactory.makeSample(latitude: 37.7749, longitude: -122.4194)

        harness.engine.consume(location: sample)

        #expect(harness.engine.currentSnapshot.currentLocation?.latitude == sample.coordinate.latitude)
        #expect(harness.engine.currentSnapshot.state == .inactive)
        #expect(harness.routeMatcher.matchedLocations.isEmpty)
    }

    @Test
    func testConsumeLocationWhenReadyUpdatesLocationOnly() async {
        let harness = NavigationEngineHarness()
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5)
        await harness.engine.send(.useRoute(route))

        let sample = LocationSampleFactory.makeSample(latitude: 37.7749, longitude: -122.4194)
        harness.engine.consume(location: sample)

        #expect(harness.engine.currentSnapshot.currentLocation?.latitude == sample.coordinate.latitude)
        #expect(harness.engine.currentSnapshot.state == .ready)
        #expect(harness.routeMatcher.matchedLocations.isEmpty)
    }

    @Test
    func testConsumeLocationWhenNavigatingMatchesRoute() async {
        let harness = NavigationEngineHarness()
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5, stepDistanceMeters: 100)
        await harness.engine.send(.useRoute(route))
        await harness.engine.send(.start)

        let match = RouteMatch(
            matchedCoordinate: Coordinate(latitude: 37.7750, longitude: -122.4194),
            segmentIndex: 1,
            segmentFraction: 0.5,
            distanceAlongRouteMeters: 150.0,
            crossTrackDistanceMeters: 2.0
        )
        harness.routeMatcher.stubbedMatch = match

        let sample = LocationSampleFactory.makeSample(latitude: 37.7750, longitude: -122.4194)
        harness.engine.consume(location: sample)

        #expect(harness.engine.currentSnapshot.currentLocation?.latitude == sample.coordinate.latitude)
        #expect(harness.engine.currentSnapshot.matchedCoordinate == match.matchedCoordinate)
        #expect(harness.engine.currentSnapshot.matchedSegmentIndex == 1)
        #expect(harness.engine.currentSnapshot.distanceAlongRouteMeters == 150.0)
        #expect(harness.engine.currentSnapshot.distanceRemainingMeters == route.totalDistanceMeters - 150.0)
        #expect(harness.engine.currentSnapshot.routeProgress == 150.0 / route.totalDistanceMeters)
    }

    @Test
    func testRouteCompletionTriggersNotificationAndCompletedState() async {
        let harness = NavigationEngineHarness()
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5, stepDistanceMeters: 100)
        await harness.engine.send(.useRoute(route))
        await harness.engine.send(.start)

        let match = RouteMatch(
            matchedCoordinate: Coordinate(latitude: 37.7789, longitude: -122.4194),
            segmentIndex: 3,
            segmentFraction: 1.0,
            distanceAlongRouteMeters: 400.0,
            crossTrackDistanceMeters: 0.0
        )
        harness.routeMatcher.stubbedMatch = match
        harness.completionEvaluator.isCompleted = true

        let sample = LocationSampleFactory.makeSample(latitude: 37.7789, longitude: -122.4194)
        harness.engine.consume(location: sample)

        try? await Task.sleep(nanoseconds: 10_000_000)

        #expect(harness.engine.currentSnapshot.state == .finished)
        #expect(harness.notificationRecorder.notifications.contains(.routeCompleted))
    }
}
