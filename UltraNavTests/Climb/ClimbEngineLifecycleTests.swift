import XCTest
@testable import UltraNav

@MainActor
final class ClimbEngineLifecycleTests: XCTestCase {
    var harness: ClimbEngineHarness!

    override func setUp() async throws {
        harness = ClimbEngineHarness()
    }

    override func tearDown() async throws {
        harness.tearDown()
        harness = nil
    }

    func testInitialStateIsUnloaded() {
        let snapshot = harness.engine.currentSnapshot
        XCTAssertEqual(snapshot.state, .unloaded)
        XCTAssertNil(snapshot.routeID)
        XCTAssertTrue(snapshot.climbs.isEmpty)
        XCTAssertNil(snapshot.activeClimb)
        XCTAssertNil(snapshot.upcomingClimb)
        XCTAssertEqual(snapshot.totalElevationGainMeters, 0)
    }

    func testLoadingRouteTransitionsThroughAnalyzingToReady() async throws {
        let route = ElevationProfileFactory.makeRoute()
        let candidate = ClimbFactory.makeCandidate(startDistanceMeters: 500, endDistanceMeters: 1500)
        harness.detector.stubbedCandidates = [candidate]

        await harness.engine.send(.loadRoute(route))

        // Yield to allow background tasks to complete
        try await Task.sleep(nanoseconds: 50_000_000)

        let snapshot = harness.engine.currentSnapshot
        XCTAssertEqual(snapshot.state, .ready)
        XCTAssertEqual(snapshot.routeID, route.id)
        XCTAssertEqual(snapshot.climbs.count, 1)
        XCTAssertNil(snapshot.activeClimb)
        XCTAssertNotNil(snapshot.upcomingClimb)
        XCTAssertEqual(snapshot.upcomingClimb?.startDistanceMeters, 500)

        XCTAssertTrue(harness.notificationRecorder.notifications.contains(where: {
            if case .routeAnalyzed(let count) = $0 { return count == 1 }
            return false
        }))
    }
}
