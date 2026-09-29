import XCTest
@testable import UltraNav

@MainActor
final class ClimbEngineFailureTests: XCTestCase {
    var harness: ClimbEngineHarness!

    override func setUp() async throws {
        harness = ClimbEngineHarness()
    }

    override func tearDown() async throws {
        harness.tearDown()
        harness = nil
    }

    func testNoElevationDataEmitsFailureAndSetsState() async throws {
        let route = ElevationProfileFactory.makeRoute()
        harness.profileBuilder.stubbedResult = .failure(.noElevationData)

        await harness.engine.send(.loadRoute(route))
        try await Task.sleep(nanoseconds: 50_000_000)

        let snapshot = harness.engine.currentSnapshot
        XCTAssertEqual(snapshot.state, .failed)
        XCTAssertEqual(snapshot.failure, .noElevationData)

        XCTAssertTrue(harness.notificationRecorder.notifications.contains(where: {
            if case .analysisFailed(let f) = $0 { return f == .noElevationData }
            return false
        }))
    }

    func testDetectorFailureSetsFailureState() async throws {
        let route = ElevationProfileFactory.makeRoute()
        harness.detector.stubbedError = .climbDetectionFailed("Bad geometry")

        await harness.engine.send(.loadRoute(route))
        try await Task.sleep(nanoseconds: 50_000_000)

        let snapshot = harness.engine.currentSnapshot
        XCTAssertEqual(snapshot.state, .failed)
        XCTAssertEqual(snapshot.failure, .climbDetectionFailed("Bad geometry"))
    }
}
