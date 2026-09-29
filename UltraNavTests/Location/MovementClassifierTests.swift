import XCTest
@testable import UltraNav

final class MovementClassifierTests: XCTestCase {
    private var classifier: MovementClassifier!
    private var config: GPSProcessingConfiguration!

    override func setUp() {
        super.setUp()
        classifier = MovementClassifier()
        config = GPSProcessingConfiguration(
            stationarySpeedThresholdMetersPerSecond: 0.8,
            movingSpeedThresholdMetersPerSecond: 1.5,
            minimumMovementDistanceMeters: 3.0,
            movementConfirmationSamples: 2,
            stationaryConfirmationSamples: 3
        )
    }

    func testTransitionsToMovingAfterConsecutiveSamples() {
        let ev = MovementEvidence(
            selectedSpeedMetersPerSecond: 4.5,
            positionDistanceMeters: 5.0,
            accuracyOverlap: false,
            timeDeltaSeconds: 1.0
        )

        // Sample 1: streak = 1 -> still unknown
        let r1 = classifier.classify(
            evidence: ev,
            previousState: .unknown,
            consecutiveMovingEvidence: 0,
            consecutiveStationaryEvidence: 0,
            configuration: config
        )
        XCTAssertEqual(r1.state, .unknown)
        XCTAssertEqual(r1.consecutiveMovingEvidence, 1)

        // Sample 2: streak = 2 (meets threshold 2) -> transitions to .moving!
        let r2 = classifier.classify(
            evidence: ev,
            previousState: r1.state,
            consecutiveMovingEvidence: r1.consecutiveMovingEvidence,
            consecutiveStationaryEvidence: r1.consecutiveStationaryEvidence,
            configuration: config
        )
        XCTAssertEqual(r2.state, .moving)
        XCTAssertEqual(r2.consecutiveMovingEvidence, 2)
    }

    func testTransitionsToStationaryAfterConsecutiveSamples() {
        let ev = MovementEvidence(
            selectedSpeedMetersPerSecond: 0.2,
            positionDistanceMeters: 1.0,
            accuracyOverlap: true,
            timeDeltaSeconds: 1.0
        )

        // Sample 1
        let r1 = classifier.classify(evidence: ev, previousState: .moving, consecutiveMovingEvidence: 5, consecutiveStationaryEvidence: 0, configuration: config)
        XCTAssertEqual(r1.state, .moving)
        XCTAssertEqual(r1.consecutiveStationaryEvidence, 1)

        // Sample 2
        let r2 = classifier.classify(evidence: ev, previousState: r1.state, consecutiveMovingEvidence: r1.consecutiveMovingEvidence, consecutiveStationaryEvidence: r1.consecutiveStationaryEvidence, configuration: config)
        XCTAssertEqual(r2.state, .moving)
        XCTAssertEqual(r2.consecutiveStationaryEvidence, 2)

        // Sample 3 (meets threshold 3) -> transitions to .stationary!
        let r3 = classifier.classify(evidence: ev, previousState: r2.state, consecutiveMovingEvidence: r2.consecutiveMovingEvidence, consecutiveStationaryEvidence: r2.consecutiveStationaryEvidence, configuration: config)
        XCTAssertEqual(r3.state, .stationary)
        XCTAssertEqual(r3.consecutiveStationaryEvidence, 3)
    }
}
