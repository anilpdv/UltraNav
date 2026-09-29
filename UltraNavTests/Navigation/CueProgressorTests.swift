import XCTest
@testable import UltraNav

final class CueProgressorTests: XCTestCase {
    private var progressor: CueProgressor!
    private var testCues: [NavigationCue]!

    override func setUp() {
        super.setUp()
        progressor = CueProgressor(
            configuration: CueProgressionConfiguration(
                approachThresholdMeters: 100.0,
                immediateThresholdMeters: 25.0,
                passedThresholdMeters: 15.0
            )
        )

        let cue1 = NavigationCue(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            maneuver: .right,
            coordinate: Coordinate(latitude: 37.3320, longitude: -122.0100),
            routeDistanceMeters: 200.0,
            instruction: "Turn right"
        )
        let cue2 = NavigationCue(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            maneuver: .left,
            coordinate: Coordinate(latitude: 37.3340, longitude: -122.0075),
            routeDistanceMeters: 500.0,
            instruction: "Turn left"
        )
        testCues = [cue1, cue2]
    }

    private func makeMatch(distanceAlongRoute: Double) -> RouteMatch {
        RouteMatch(
            matchedCoordinate: Coordinate(latitude: 37.3300, longitude: -122.0100),
            segmentIndex: 0,
            segmentFraction: 0.0,
            distanceAlongRouteMeters: distanceAlongRoute,
            crossTrackDistanceMeters: 2.0,
            headingDifferenceDegrees: 0.0,
            confidence: .high
        )
    }

    func testDistantPhase() {
        let match = makeMatch(distanceAlongRoute: 50.0) // 150m from cue 1 (> 100m)
        let result = progressor.progress(cues: testCues, routeMatch: match, previous: nil)

        XCTAssertEqual(result.nextCue?.id, testCues[0].id)
        XCTAssertEqual(result.distanceToNextCueMeters, 150.0)
        XCTAssertEqual(result.phase, .distant)
        XCTAssertNil(result.pendingNotification)
    }

    func testApproachPhaseEmitsNotificationOnce() {
        let match1 = makeMatch(distanceAlongRoute: 120.0) // 80m from cue 1 (<= 100m)
        let result1 = progressor.progress(cues: testCues, routeMatch: match1, previous: nil)

        XCTAssertEqual(result1.phase, .approaching)
        XCTAssertEqual(result1.pendingNotification, .approachingCue(testCues[0]))

        // Subsequent location update within approach zone should NOT re-emit notification
        let match2 = makeMatch(distanceAlongRoute: 150.0) // 50m from cue 1
        let result2 = progressor.progress(cues: testCues, routeMatch: match2, previous: result1)

        XCTAssertEqual(result2.phase, .approaching)
        XCTAssertNil(result2.pendingNotification)
    }

    func testImmediatePhaseEmitsNotificationOnce() {
        let match1 = makeMatch(distanceAlongRoute: 180.0) // 20m from cue 1 (<= 25m)
        let result1 = progressor.progress(cues: testCues, routeMatch: match1, previous: nil)

        XCTAssertEqual(result1.phase, .immediate)
        XCTAssertEqual(result1.pendingNotification, .immediateCue(testCues[0]))

        let match2 = makeMatch(distanceAlongRoute: 195.0) // 5m from cue 1
        let result2 = progressor.progress(cues: testCues, routeMatch: match2, previous: result1)

        XCTAssertEqual(result2.phase, .immediate)
        XCTAssertNil(result2.pendingNotification)
    }

    func testPassingCueAdvancesToNextCue() {
        // Cue 1 is at 200m. Passed threshold is +15m -> passed at >= 215m.
        let match = makeMatch(distanceAlongRoute: 220.0)
        let result = progressor.progress(cues: testCues, routeMatch: match, previous: nil)

        XCTAssertTrue(result.passedCueIDs.contains(testCues[0].id))
        XCTAssertEqual(result.nextCue?.id, testCues[1].id)
        XCTAssertEqual(result.distanceToNextCueMeters, 280.0) // 500 - 220
        XCTAssertEqual(result.phase, .distant)
    }

    func testBacktrackingDoesNotReplayAlerts() {
        // Step 1: User approaches Cue 1
        let match1 = makeMatch(distanceAlongRoute: 120.0)
        let result1 = progressor.progress(cues: testCues, routeMatch: match1, previous: nil)
        XCTAssertEqual(result1.pendingNotification, .approachingCue(testCues[0]))

        // Step 2: User passes Cue 1
        let match2 = makeMatch(distanceAlongRoute: 220.0)
        let result2 = progressor.progress(cues: testCues, routeMatch: match2, previous: result1)
        XCTAssertTrue(result2.passedCueIDs.contains(testCues[0].id))

        // Step 3: User backtracks to 150m (before Cue 1)
        let match3 = makeMatch(distanceAlongRoute: 150.0)
        let result3 = progressor.progress(cues: testCues, routeMatch: match3, previous: result2)

        // Cue 1 remains passed; active cue is still Cue 2
        XCTAssertTrue(result3.passedCueIDs.contains(testCues[0].id))
        XCTAssertEqual(result3.nextCue?.id, testCues[1].id)
        XCTAssertNil(result3.pendingNotification)
    }
}
