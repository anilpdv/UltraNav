import XCTest
@testable import UltraNav

final class RejoinCandidateSearcherTests: XCTestCase {
    private var searcher: RejoinCandidateSearcher!
    private var testRoute: Route!
    private var routeIndex: RouteGeometryIndex!

    override func setUp() {
        super.setUp()
        searcher = RejoinCandidateSearcher()

        // Create a 3-point straight route: (0,0) -> (0.01, 0) -> (0.02, 0)
        let points = [
            RoutePoint(coordinate: Coordinate(latitude: 37.7749, longitude: -122.4194), cumulativeDistanceMeters: 0.0),
            RoutePoint(coordinate: Coordinate(latitude: 37.7794, longitude: -122.4194), cumulativeDistanceMeters: 500.0),
            RoutePoint(coordinate: Coordinate(latitude: 37.7839, longitude: -122.4194), cumulativeDistanceMeters: 1000.0)
        ]
        testRoute = Route(
            id: RouteID(uuid: UUID()),
            metadata: RouteMetadata(name: "Test Rejoin Route"),
            points: points,
            totalDistanceMeters: 1000.0
        )
        routeIndex = RouteGeometryIndex(route: testRoute)
    }

    private func makeSample(lat: Double, lon: Double, speed: Double = 5.0, course: Double? = 0.0) -> GPSAcceptedSample {
        let loc = LocationSample(
            coordinate: Coordinate(latitude: lat, longitude: lon),
            altitudeMeters: 10.0,
            horizontalAccuracyMeters: 5.0,
            speedMetersPerSecond: speed,
            courseDegrees: course,
            timestamp: Date()
        )
        return GPSAcceptedSample(
            sample: loc,
            quality: .good,
            selectedSpeedMetersPerSecond: speed,
            movementState: .moving,
            distanceIncrementMeters: 0.0,
            totalDistanceMeters: 0.0,
            sequence: 1
        )
    }

    func test_searcher_findsNearbyCandidateOnRoute() async throws {
        let sample = makeSample(lat: 37.7770, lon: -122.4194, speed: 5.0, course: 0.0)
        let context = RejoinSearchContext(
            routeID: testRoute.id,
            lastStableMatch: nil,
            maximumReachedDistanceMeters: 0.0,
            travelDirectionBeforeDeviation: .forward,
            currentMovementState: .moving,
            currentLocation: sample,
            currentEpisode: OffRouteEpisode()
        )

        let candidates = try await searcher.candidates(
            index: routeIndex,
            context: context,
            configuration: .standard
        )

        XCTAssertFalse(candidates.isEmpty)
        let best = candidates[0]
        XCTAssertEqual(best.routeMatch.segmentIndex, 0)
        XCTAssertLessThan(best.routeMatch.crossTrackDistanceMeters, 5.0)
        XCTAssertEqual(best.confidence, .high)
    }

    func test_searcher_ranksForwardCandidateHigherThanFarBackward() async throws {
        // Last stable match at 200m
        let lastMatch = RouteMatch(
            matchedCoordinate: Coordinate(latitude: 37.7765, longitude: -122.4194),
            segmentIndex: 0,
            segmentFraction: 0.4,
            distanceAlongRouteMeters: 200.0,
            crossTrackDistanceMeters: 2.0
        )

        let sample = makeSample(lat: 37.7780, lon: -122.4194, speed: 6.0, course: 0.0)
        let context = RejoinSearchContext(
            routeID: testRoute.id,
            lastStableMatch: lastMatch,
            maximumReachedDistanceMeters: 200.0,
            travelDirectionBeforeDeviation: .forward,
            currentMovementState: .moving,
            currentLocation: sample,
            currentEpisode: OffRouteEpisode()
        )

        let candidates = try await searcher.candidates(
            index: routeIndex,
            context: context,
            configuration: .standard
        )

        XCTAssertFalse(candidates.isEmpty)
        let top = candidates[0]
        XCTAssertGreaterThan(top.routeMatch.distanceAlongRouteMeters, 200.0)
        XCTAssertGreaterThanOrEqual(top.forwardPreferenceScore, 0.7)
    }

    func test_searcher_filtersCandidatesBeyondMaximumCrossTrack() async throws {
        // Point far away (1km off track)
        let sample = makeSample(lat: 37.7770, lon: -122.3500)
        let context = RejoinSearchContext(
            routeID: testRoute.id,
            lastStableMatch: nil,
            maximumReachedDistanceMeters: 0.0,
            travelDirectionBeforeDeviation: .forward,
            currentMovementState: .moving,
            currentLocation: sample,
            currentEpisode: OffRouteEpisode()
        )

        let candidates = try await searcher.candidates(
            index: routeIndex,
            context: context,
            configuration: .standard
        )

        XCTAssertTrue(candidates.isEmpty)
    }
}
