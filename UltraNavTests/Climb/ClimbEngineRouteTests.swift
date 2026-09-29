import XCTest
@testable import UltraNav

@MainActor
final class ClimbEngineRouteTests: XCTestCase {
    var harness: ClimbEngineHarness!

    override func setUp() async throws {
        harness = ClimbEngineHarness()
    }

    override func tearDown() async throws {
        harness.tearDown()
        harness = nil
    }

    func testMultipleClimbsCategorizedAndIndexedProperly() async throws {
        let route = ElevationProfileFactory.makeRoute()
        let c1 = ClimbFactory.makeCandidate(startDistanceMeters: 500, endDistanceMeters: 1500)
        let c2 = ClimbFactory.makeCandidate(startDistanceMeters: 2000, endDistanceMeters: 3500)
        harness.detector.stubbedCandidates = [c1, c2]

        await harness.engine.send(.loadRoute(route))
        try await Task.sleep(nanoseconds: 50_000_000)

        let snapshot = harness.engine.currentSnapshot
        XCTAssertEqual(snapshot.climbs.count, 2)
        XCTAssertEqual(snapshot.climbs[0].climbIndex, 1)
        XCTAssertEqual(snapshot.climbs[0].totalClimbs, 2)
        XCTAssertEqual(snapshot.climbs[1].climbIndex, 2)
        XCTAssertEqual(snapshot.climbs[1].totalClimbs, 2)
    }

    func testRouteWithoutClimbsTransitionsToReady() async throws {
        let route = ElevationProfileFactory.makeRoute()
        harness.detector.stubbedCandidates = []

        await harness.engine.send(.loadRoute(route))
        try await Task.sleep(nanoseconds: 50_000_000)

        let snapshot = harness.engine.currentSnapshot
        XCTAssertEqual(snapshot.state, .ready)
        XCTAssertTrue(snapshot.climbs.isEmpty)
        XCTAssertNil(snapshot.activeClimb)
        XCTAssertNil(snapshot.upcomingClimb)
    }
}
