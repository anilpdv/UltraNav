import XCTest
@testable import UltraNav

@MainActor
final class ClimbEngineCompletionTests: XCTestCase {
    var harness: ClimbEngineHarness!

    override func setUp() async throws {
        harness = ClimbEngineHarness()
    }

    override func tearDown() async throws {
        harness.tearDown()
        harness = nil
    }

    func testClimbCompletionEmitsNotificationAndAdvancesCompletedIDs() async throws {
        let route = ElevationProfileFactory.makeRoute()
        let c1 = ClimbFactory.makeCandidate(startDistanceMeters: 1000, endDistanceMeters: 2000)
        harness.detector.stubbedCandidates = [c1]

        await harness.engine.send(.loadRoute(route))
        try await Task.sleep(nanoseconds: 50_000_000)

        // Enter climb
        await harness.engine.send(.processNavigation(ElevationProfileFactory.makeNavSnapshot(distanceAlongRoute: 1500)))

        // Exit climb at 2100m
        await harness.engine.send(.processNavigation(ElevationProfileFactory.makeNavSnapshot(distanceAlongRoute: 2100)))
        try await Task.sleep(nanoseconds: 10_000_000)

        let snapshot = harness.engine.currentSnapshot
        XCTAssertEqual(snapshot.state, .completedAllClimbs)
        XCTAssertNil(snapshot.activeClimb)
        XCTAssertEqual(snapshot.completedClimbsCount, 1)

        XCTAssertTrue(harness.notificationRecorder.notifications.contains(where: {
            if case .climbCompleted(let climb) = $0 { return climb.climbIndex == 1 }
            return false
        }))
        XCTAssertTrue(harness.notificationRecorder.notifications.contains(where: {
            if case .allClimbsCompleted = $0 { return true }
            return false
        }))
    }

    func testSkippedClimbEmitsSkippedNotification() async throws {
        let route = ElevationProfileFactory.makeRoute()
        let c1 = ClimbFactory.makeCandidate(startDistanceMeters: 1000, endDistanceMeters: 2000)
        let c2 = ClimbFactory.makeCandidate(startDistanceMeters: 3000, endDistanceMeters: 4000)
        harness.detector.stubbedCandidates = [c1, c2]

        await harness.engine.send(.loadRoute(route))
        try await Task.sleep(nanoseconds: 50_000_000)

        // Jump straight to 2500m (skipping c1)
        await harness.engine.send(.processNavigation(ElevationProfileFactory.makeNavSnapshot(distanceAlongRoute: 2500)))
        try await Task.sleep(nanoseconds: 10_000_000)

        let snapshot = harness.engine.currentSnapshot
        XCTAssertEqual(snapshot.state, .ready)
        XCTAssertEqual(snapshot.completedClimbsCount, 1)
        XCTAssertEqual(snapshot.upcomingClimb?.climbIndex, 2)

        XCTAssertTrue(harness.notificationRecorder.notifications.contains(where: {
            if case .climbSkipped(let climb) = $0 { return climb.climbIndex == 1 }
            return false
        }))
    }
}
