import XCTest
@testable import UltraNav

@MainActor
final class ClimbEngineResetTests: XCTestCase {
    var harness: ClimbEngineHarness!

    override func setUp() async throws {
        harness = ClimbEngineHarness()
    }

    override func tearDown() async throws {
        harness.tearDown()
        harness = nil
    }

    func testResetClearsAllClimbsAndRestoresUnloadedState() async throws {
        let route = ElevationProfileFactory.makeRoute()
        let c1 = ClimbFactory.makeCandidate(startDistanceMeters: 500, endDistanceMeters: 1500)
        harness.detector.stubbedCandidates = [c1]

        await harness.engine.send(.loadRoute(route))
        try await Task.sleep(nanoseconds: 50_000_000)

        await harness.engine.send(.processLocation(LocationSample(
            coordinate: Coordinate(latitude: 37, longitude: -122),
            altitudeMeters: 120,
            horizontalAccuracyMeters: 5,
            timestamp: Date()
        )))

        await harness.engine.send(.reset)

        let snapshot = harness.engine.currentSnapshot
        XCTAssertEqual(snapshot.state, .unloaded)
        XCTAssertNil(snapshot.routeID)
        XCTAssertTrue(snapshot.climbs.isEmpty)
        XCTAssertNil(snapshot.activeClimb)
        XCTAssertEqual(snapshot.totalElevationGainMeters, 0)
        XCTAssertNil(snapshot.currentElevationMeters)
    }
}
