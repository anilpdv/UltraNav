import XCTest
@testable import UltraNav

final class RejoinEvaluatorTests: XCTestCase {
    private var evaluator: RejoinEvaluator!
    private var config: RejoinConfiguration!
    private var context: RejoinSearchContext!

    override func setUp() {
        super.setUp()
        evaluator = RejoinEvaluator()
        config = RejoinConfiguration.standard

        let sample = GPSAcceptedSample(
            sample: LocationSample(
                coordinate: Coordinate(latitude: 37.7749, longitude: -122.4194),
                altitudeMeters: 0,
                horizontalAccuracyMeters: 5,
                speedMetersPerSecond: 5,
                courseDegrees: 0,
                timestamp: Date()
            ),
            quality: .good,
            selectedSpeedMetersPerSecond: 5.0,
            movementState: .moving,
            distanceIncrementMeters: 0.0,
            totalDistanceMeters: 0.0,
            sequence: 1
        )

        context = RejoinSearchContext(
            routeID: RouteID(uuid: UUID()),
            lastStableMatch: nil,
            maximumReachedDistanceMeters: 100.0,
            travelDirectionBeforeDeviation: .forward,
            currentMovementState: .moving,
            currentLocation: sample,
            currentEpisode: OffRouteEpisode()
        )
    }

    private func makeCandidate(
        crossTrack: Double,
        delta: Double = 10.0,
        confidence: RejoinConfidence = .high,
        ambiguity: Double = 0.0,
        headingDiff: Double? = nil
    ) -> RejoinCandidate {
        let match = RouteMatch(
            matchedCoordinate: Coordinate(latitude: 37.7749, longitude: -122.4194),
            segmentIndex: 0,
            segmentFraction: 0.5,
            distanceAlongRouteMeters: 110.0,
            crossTrackDistanceMeters: crossTrack,
            headingDifferenceDegrees: headingDiff,
            confidence: confidence == .high ? .high : .medium
        )
        return RejoinCandidate(
            routeMatch: match,
            progressDeltaFromLastStableMeters: delta,
            crossTrackScore: 0.9,
            continuityScore: 0.9,
            headingScore: 0.9,
            forwardPreferenceScore: 0.9,
            ambiguityPenalty: ambiguity,
            totalScore: 0.85,
            confidence: confidence
        )
    }

    func test_emptyCandidates_returnsUnavailable() {
        let decision = evaluator.evaluate(
            candidates: [],
            previousCandidate: nil,
            confirmationCount: 0,
            context: context,
            configuration: config
        )
        XCTAssertEqual(decision, .unavailable(.noCandidatesWithinRadius))
    }

    func test_ambiguousCandidate_returnsWaitForEvidence() {
        let candidate = makeCandidate(crossTrack: 5.0, ambiguity: 0.2)
        let decision = evaluator.evaluate(
            candidates: [candidate],
            previousCandidate: nil,
            confirmationCount: 1,
            context: context,
            configuration: config
        )
        XCTAssertEqual(decision, .waitForEvidence(reason: .ambiguousCandidates))
    }

    func test_singleObservation_returnsCandidateAvailable() {
        let candidate = makeCandidate(crossTrack: 15.0, confidence: .medium)
        let decision = evaluator.evaluate(
            candidates: [candidate],
            previousCandidate: nil,
            confirmationCount: 1,
            context: context,
            configuration: config
        )
        XCTAssertEqual(decision, .candidateAvailable(candidate))
    }

    func test_confirmedCandidate_returnsRejoined() {
        let candidate = makeCandidate(crossTrack: 15.0, confidence: .medium)
        let decision = evaluator.evaluate(
            candidates: [candidate],
            previousCandidate: candidate,
            confirmationCount: 2, // Meets requiredConfirmations = 2
            context: context,
            configuration: config
        )
        XCTAssertEqual(decision, .rejoined(candidate))
    }

    func test_highConfidenceTightProximity_rejoinsOnFirstConfirmation() {
        let candidate = makeCandidate(crossTrack: 5.0, delta: 10.0, confidence: .high)
        let decision = evaluator.evaluate(
            candidates: [candidate],
            previousCandidate: nil,
            confirmationCount: 1,
            context: context,
            configuration: config
        )
        XCTAssertEqual(decision, .rejoined(candidate))
    }
}
