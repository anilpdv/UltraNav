import XCTest
@testable import UltraNav

@MainActor
final class ClimbEngineProgressTests: XCTestCase {
    var harness: ClimbEngineHarness!

    override func setUp() async throws {
        harness = ClimbEngineHarness()
    }

    override func tearDown() async throws {
        harness.tearDown()
        harness = nil
    }

    func testClimbProgressCalculationUpdatesAccurately() async throws {
        let route = ElevationProfileFactory.makeRoute()
        let c1 = ClimbFactory.makeCandidate(
            startDistanceMeters: 1000,
            endDistanceMeters: 3000,
            startElevationMeters: 100,
            endElevationMeters: 300,
            summitElevationMeters: 300,
            netElevationGainMeters: 200,
            totalElevationGainMeters: 200,
            averageGradientRatio: 0.10
        )
        harness.detector.stubbedCandidates = [c1]

        await harness.engine.send(.loadRoute(route))
        try await Task.sleep(nanoseconds: 50_000_000)

        // Progress halfway through climb at 2000m
        let nav = ElevationProfileFactory.makeNavSnapshot(distanceAlongRoute: 2000, offRouteStatus: .onRoute)
        await harness.engine.send(.processNavigation(nav))

        let snapshot = harness.engine.currentSnapshot
        guard let progress = snapshot.activeClimbProgress else {
            XCTFail("Expected active climb progress")
            return
        }

        XCTAssertEqual(progress.distanceIntoClimbMeters, 1000, accuracy: 0.1)
        XCTAssertEqual(progress.distanceRemainingMeters, 1000, accuracy: 0.1)
        XCTAssertEqual(progress.fractionCompleted, 0.5, accuracy: 0.01)
        XCTAssertEqual(progress.quality, .reliable)
    }

    func testOffRouteDegradesProgressQuality() async throws {
        let route = ElevationProfileFactory.makeRoute()
        let c1 = ClimbFactory.makeCandidate(startDistanceMeters: 1000, endDistanceMeters: 2000)
        harness.detector.stubbedCandidates = [c1]

        await harness.engine.send(.loadRoute(route))
        try await Task.sleep(nanoseconds: 50_000_000)

        let nav = ElevationProfileFactory.makeNavSnapshot(distanceAlongRoute: 1500, offRouteStatus: .offRoute)
        await harness.engine.send(.processNavigation(nav))

        let snapshot = harness.engine.currentSnapshot
        XCTAssertEqual(snapshot.activeClimbProgress?.quality, .unavailable)
    }
}
