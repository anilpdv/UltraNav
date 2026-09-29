import Testing
import Foundation
@testable import UltraNav

@MainActor
struct NavigationEngineCueTests {
    @Test
    func testCuesLoadedWithRoute() async {
        let harness = NavigationEngineHarness()
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5)
        let cue1 = NavigationRouteFactory.createCue(maneuver: .left, distanceMeters: 200)
        let cue2 = NavigationRouteFactory.createCue(maneuver: .right, distanceMeters: 400)
        harness.cueProvider.cues = [cue1, cue2]

        await harness.engine.send(.useRoute(route))

        #expect(harness.engine.routeState.cues.count == 2)
        #expect(harness.engine.routeState.cues.first?.maneuver == .left)
    }

    @Test
    func testCueProgressionUpdatesActiveCue() async {
        let harness = NavigationEngineHarness()
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5, stepDistanceMeters: 100)
        let cue1 = NavigationRouteFactory.createCue(maneuver: .left, distanceMeters: 200)
        harness.cueProvider.cues = [cue1]

        await harness.engine.send(.useRoute(route))
        await harness.engine.send(.start)

        harness.cueProgressor.stubbedProgress = CueProgress(
            nextCue: cue1,
            distanceToNextCueMeters: 100.0,
            passedCueIDs: []
        )

        harness.routeMatcher.stubbedMatch = RouteMatch(
            matchedCoordinate: Coordinate(latitude: 37.7750, longitude: -122.4194),
            segmentIndex: 1,
            segmentFraction: 0.0,
            distanceAlongRouteMeters: 100.0,
            crossTrackDistanceMeters: 0.0
        )

        harness.engine.consume(location: LocationSampleFactory.makeSample(latitude: 37.7750, longitude: -122.4194))

        #expect(harness.engine.currentSnapshot.nextCue?.id == cue1.id)
        #expect(harness.engine.currentSnapshot.distanceToNextCueMeters == 100.0)
    }
}
