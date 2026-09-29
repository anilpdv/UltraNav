import XCTest
@testable import UltraNav

@MainActor
final class ClimbEngineSelectionTests: XCTestCase {
    var harness: ClimbEngineHarness!

    override func setUp() async throws {
        harness = ClimbEngineHarness()
    }

    override func tearDown() async throws {
        harness.tearDown()
        harness = nil
    }

    func testApproachingNotificationEmittedWhenWithin500Meters() async throws {
        let route = ElevationProfileFactory.makeRoute()
        let c1 = ClimbFactory.makeCandidate(startDistanceMeters: 1000, endDistanceMeters: 2000)
        harness.detector.stubbedCandidates = [c1]

        await harness.engine.send(.loadRoute(route))
        try await Task.sleep(nanoseconds: 50_000_000)

        // Progress at 400m -> 600m away (not approaching)
        let nav1 = ElevationProfileFactory.makeNavSnapshot(distanceAlongRoute: 400)
        await harness.engine.send(.processNavigation(nav1))

        XCTAssertFalse(harness.notificationRecorder.notifications.contains(where: {
            if case .climbApproaching = $0 { return true }
            return false
        }))

        // Progress at 600m -> 400m away (approaching!)
        let nav2 = ElevationProfileFactory.makeNavSnapshot(distanceAlongRoute: 600)
        await harness.engine.send(.processNavigation(nav2))
        try await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertTrue(harness.notificationRecorder.notifications.contains(where: {
            if case .climbApproaching(let climb, let dist) = $0 {
                return climb.climbIndex == 1 && dist == 400
            }
            return false
        }))
    }

    func testClimbActivationTransitionsStateToActiveClimb() async throws {
        let route = ElevationProfileFactory.makeRoute()
        let c1 = ClimbFactory.makeCandidate(startDistanceMeters: 1000, endDistanceMeters: 2000)
        harness.detector.stubbedCandidates = [c1]

        await harness.engine.send(.loadRoute(route))
        try await Task.sleep(nanoseconds: 50_000_000)

        // Enter climb at 1200m
        let nav = ElevationProfileFactory.makeNavSnapshot(distanceAlongRoute: 1200)
        await harness.engine.send(.processNavigation(nav))
        try await Task.sleep(nanoseconds: 10_000_000)

        let snapshot = harness.engine.currentSnapshot
        XCTAssertEqual(snapshot.state, .activeClimb)
        XCTAssertNotNil(snapshot.activeClimb)
        XCTAssertEqual(snapshot.activeClimb?.climbIndex, 1)
        XCTAssertNotNil(snapshot.activeClimbProgress)

        XCTAssertTrue(harness.notificationRecorder.notifications.contains(where: {
            if case .climbStarted(let climb) = $0 { return climb.climbIndex == 1 }
            return false
        }))
    }
}
