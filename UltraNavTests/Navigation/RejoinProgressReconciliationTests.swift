import XCTest
@testable import UltraNav

final class RejoinProgressReconciliationTests: XCTestCase {
    private var reconciler: RejoinProgressReconciler!

    override func setUp() {
        super.setUp()
        reconciler = RejoinProgressReconciler()
    }

    private func makeCandidate(distance: Double) -> RejoinCandidate {
        let match = RouteMatch(
            matchedCoordinate: Coordinate(latitude: 37.7749, longitude: -122.4194),
            segmentIndex: 0,
            distanceAlongRouteMeters: distance,
            crossTrackDistanceMeters: 5.0
        )
        return RejoinCandidate(
            routeMatch: match,
            progressDeltaFromLastStableMeters: 0,
            crossTrackScore: 1.0,
            continuityScore: 1.0,
            forwardPreferenceScore: 1.0,
            totalScore: 1.0,
            confidence: .high
        )
    }

    func test_sameSectionRejoin() {
        let candidate = makeCandidate(distance: 105.0)
        let result = reconciler.reconcile(
            previousDistanceMeters: 100.0,
            maximumReachedDistanceMeters: 100.0,
            candidate: candidate,
            routeTotalDistanceMeters: 5000.0
        )
        XCTAssertEqual(result.outcome, .sameSection)
        XCTAssertEqual(result.rejoinedDistanceMeters, 105.0)
        XCTAssertEqual(result.newMaximumReachedDistanceMeters, 105.0)
    }

    func test_forwardSkipRejoin() {
        let candidate = makeCandidate(distance: 800.0)
        let result = reconciler.reconcile(
            previousDistanceMeters: 100.0,
            maximumReachedDistanceMeters: 100.0,
            candidate: candidate,
            routeTotalDistanceMeters: 5000.0
        )
        XCTAssertEqual(result.outcome, .largeForwardSkip)
        XCTAssertEqual(result.skippedForwardDistanceMeters, 700.0)
        XCTAssertEqual(result.newMaximumReachedDistanceMeters, 800.0)
    }

    func test_backwardRejoin_preservesMaximumReachedDistance() {
        let candidate = makeCandidate(distance: 200.0)
        let result = reconciler.reconcile(
            previousDistanceMeters: 300.0,
            maximumReachedDistanceMeters: 500.0,
            candidate: candidate,
            routeTotalDistanceMeters: 5000.0,
            policy: .standard
        )
        XCTAssertEqual(result.outcome, .movedBackward)
        XCTAssertEqual(result.rejoinedDistanceMeters, 200.0)
        XCTAssertEqual(result.newMaximumReachedDistanceMeters, 500.0)
    }
}
