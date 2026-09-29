import Testing
import Foundation
@testable import UltraNav

@MainActor
struct NavigationEngineOffRouteTests {
    @Test
    func testOffRouteTransitionTriggersNotificationAndState() async {
        let harness = NavigationEngineHarness()
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5)
        await harness.engine.send(.useRoute(route))
        await harness.engine.send(.start)

        #expect(harness.engine.currentSnapshot.offRouteStatus == .unknown)

        harness.routeMatcher.stubbedMatch = RouteMatch(
            matchedCoordinate: Coordinate(latitude: 37.7800, longitude: -122.4300),
            segmentIndex: 0,
            distanceAlongRouteMeters: 0,
            crossTrackDistanceMeters: 100.0
        )
        harness.offRouteEvaluator.stubbedEvaluation = OffRouteEvaluation(status: .offRoute, shouldNotify: true)

        let sample = LocationSampleFactory.makeSample(latitude: 37.7800, longitude: -122.4300)
        harness.engine.consume(location: sample)

        try? await Task.sleep(nanoseconds: 10_000_000)

        #expect(harness.engine.currentSnapshot.offRouteStatus == .offRoute)
        #expect(harness.notificationRecorder.notifications.contains(.offRoute))
    }

    @Test
    func testRejoiningRouteTriggersNotification() async {
        let harness = NavigationEngineHarness()
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5)
        await harness.engine.send(.useRoute(route))
        await harness.engine.send(.start)

        // Go off route
        harness.routeMatcher.stubbedMatch = RouteMatch(
            matchedCoordinate: Coordinate(latitude: 37.7800, longitude: -122.4300),
            segmentIndex: 0,
            distanceAlongRouteMeters: 0,
            crossTrackDistanceMeters: 100.0
        )
        harness.offRouteEvaluator.stubbedEvaluation = OffRouteEvaluation(status: .offRoute, shouldNotify: true)
        harness.engine.consume(location: LocationSampleFactory.makeSample(latitude: 37.7800, longitude: -122.4300))

        // Rejoin
        harness.routeMatcher.stubbedMatch = RouteMatch(
            matchedCoordinate: Coordinate(latitude: 37.7750, longitude: -122.4194),
            segmentIndex: 1,
            distanceAlongRouteMeters: 100,
            crossTrackDistanceMeters: 5.0
        )
        harness.offRouteEvaluator.stubbedEvaluation = OffRouteEvaluation(status: .onRoute, shouldNotify: true)
        harness.engine.consume(location: LocationSampleFactory.makeSample(latitude: 37.7750, longitude: -122.4194))

        try? await Task.sleep(nanoseconds: 10_000_000)

        #expect(harness.engine.currentSnapshot.offRouteStatus == .onRoute)
        #expect(harness.notificationRecorder.notifications.contains(.routeRejoined))
    }
}
