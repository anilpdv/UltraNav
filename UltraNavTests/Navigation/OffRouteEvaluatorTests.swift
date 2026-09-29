import XCTest
@testable import UltraNav

final class OffRouteEvaluatorTests: XCTestCase {
    private var evaluator: OffRouteEvaluator!
    private var config: OffRouteConfiguration!

    override func setUp() {
        super.setUp()
        config = OffRouteConfiguration(
            suspectedDistanceThresholdMeters: 35.0,
            confirmedDistanceThresholdMeters: 55.0,
            recoveryDistanceThresholdMeters: 20.0,
            consecutiveEvidenceCount: 3,
            confirmationDurationSeconds: 5.0,
            maximumHeadingDifferenceDegrees: 90.0
        )
        evaluator = OffRouteEvaluator(configuration: config)
    }

    private func makeMatch(crossTrack: Double, headingDiff: Double? = nil, confidence: RouteMatchingConfidence = .high) -> RouteMatch {
        RouteMatch(
            matchedCoordinate: Coordinate(latitude: 37.7749, longitude: -122.4194),
            segmentIndex: 0,
            segmentFraction: 0.5,
            distanceAlongRouteMeters: 100.0,
            crossTrackDistanceMeters: crossTrack,
            headingDifferenceDegrees: headingDiff,
            confidence: confidence
        )
    }

    func test_singleNoisySample_doesNotImmediatelyConfirmOffRoute() {
        let baseDate = Date()
        let match = makeMatch(crossTrack: 60.0) // Above confirmed threshold (55m)

        let result = evaluator.evaluate(match: match, previousStatus: .onRoute, timestamp: baseDate)
        XCTAssertEqual(result.status, .suspected)
        XCTAssertFalse(result.shouldNotify)
    }

    func test_consecutiveOffRouteSamples_confirmsDeviation() {
        let baseDate = Date()
        let match = makeMatch(crossTrack: 60.0)

        _ = evaluator.evaluate(match: match, previousStatus: .onRoute, timestamp: baseDate)
        let eval2 = evaluator.evaluate(match: match, previousStatus: .suspected, timestamp: baseDate.addingTimeInterval(1.0))
        XCTAssertEqual(eval2.status, .suspected)
        XCTAssertFalse(eval2.shouldNotify)

        let eval3 = evaluator.evaluate(match: match, previousStatus: .suspected, timestamp: baseDate.addingTimeInterval(2.0))
        XCTAssertEqual(eval3.status, .offRoute)
        XCTAssertTrue(eval3.shouldNotify)
    }

    func test_durationBasedDeviation_confirmsDeviationAfterThreshold() {
        let baseDate = Date()
        let match = makeMatch(crossTrack: 60.0)

        // Sample 1 at t=0
        _ = evaluator.evaluate(match: match, previousStatus: .onRoute, timestamp: baseDate)

        // Sample 2 at t=5.5s (exceeds 5.0s confirmationDurationSeconds)
        let eval2 = evaluator.evaluate(match: match, previousStatus: .suspected, timestamp: baseDate.addingTimeInterval(5.5))
        XCTAssertEqual(eval2.status, .offRoute)
        XCTAssertTrue(eval2.shouldNotify)
    }

    func test_hysteresisRecovery_requiresCloseProximityAndConsecutiveEvidence() {
        let baseDate = Date()
        let offMatch = makeMatch(crossTrack: 60.0)
        _ = evaluator.evaluate(match: offMatch, previousStatus: .onRoute, timestamp: baseDate)
        _ = evaluator.evaluate(match: offMatch, previousStatus: .suspected, timestamp: baseDate.addingTimeInterval(1.0))
        _ = evaluator.evaluate(match: offMatch, previousStatus: .suspected, timestamp: baseDate.addingTimeInterval(2.0))

        // Off-route status is now confirmed. Recovery match at 15m (<= 20m recovery threshold)
        let recoverMatch = makeMatch(crossTrack: 15.0)
        let rec1 = evaluator.evaluate(match: recoverMatch, previousStatus: .offRoute, timestamp: baseDate.addingTimeInterval(3.0))
        XCTAssertEqual(rec1.status, .rejoining)
        XCTAssertFalse(rec1.shouldNotify)

        let rec2 = evaluator.evaluate(match: recoverMatch, previousStatus: .rejoining, timestamp: baseDate.addingTimeInterval(4.0))
        XCTAssertEqual(rec2.status, .onRoute)
        XCTAssertTrue(rec2.shouldNotify)
    }

    func test_severeHeadingMismatch_amplifiesEffectiveCrossTrack() {
        let baseDate = Date()
        // 40m cross track is normally only suspected (35m-55m), but with 120 deg heading mismatch (and medium confidence), effective cross track = 60m
        let match = makeMatch(crossTrack: 40.0, headingDiff: 120.0, confidence: .medium)

        _ = evaluator.evaluate(match: match, previousStatus: .onRoute, timestamp: baseDate)
        _ = evaluator.evaluate(match: match, previousStatus: .suspected, timestamp: baseDate.addingTimeInterval(1.0))
        let eval3 = evaluator.evaluate(match: match, previousStatus: .suspected, timestamp: baseDate.addingTimeInterval(2.0))

        XCTAssertEqual(eval3.status, .offRoute)
        XCTAssertTrue(eval3.shouldNotify)
    }

    func test_reset_cleansEvidence() {
        let baseDate = Date()
        let match = makeMatch(crossTrack: 60.0)
        _ = evaluator.evaluate(match: match, previousStatus: .onRoute, timestamp: baseDate)
        _ = evaluator.evaluate(match: match, previousStatus: .suspected, timestamp: baseDate.addingTimeInterval(1.0))

        evaluator.reset()

        // After reset, 1st sample starts fresh
        let freshEval = evaluator.evaluate(match: match, previousStatus: .onRoute, timestamp: baseDate.addingTimeInterval(2.0))
        XCTAssertEqual(freshEval.status, .suspected)
        XCTAssertFalse(freshEval.shouldNotify)
    }
}
