import XCTest
@testable import UltraNav

@MainActor
final class ClimbEngineIntegrationTests: XCTestCase {
    var engine: ClimbEngine!
    var snapshotRecorder: ClimbSnapshotRecorder!
    var notificationRecorder: ClimbNotificationRecorder!

    override func setUp() async throws {
        let analysisService = ClimbAnalysisService(
            profileBuilder: LegacyElevationProfileBuilder(),
            detector: LegacyClimbDetector(),
            assembler: ClimbAssembler(classifier: LegacyClimbClassifier())
        )

        engine = ClimbEngine(
            analysisService: analysisService,
            selector: StandardActiveClimbSelector(),
            progressCalculator: StandardClimbProgressCalculator(),
            snapshotBuilder: ClimbSnapshotBuilder()
        )

        snapshotRecorder = ClimbSnapshotRecorder()
        notificationRecorder = ClimbNotificationRecorder()

        snapshotRecorder.startRecording(stream: engine.snapshots)
        notificationRecorder.startRecording(stream: engine.notifications)
    }

    override func tearDown() async throws {
        snapshotRecorder.stopRecording()
        notificationRecorder.stopRecording()
        engine = nil
    }

    func testRealProfileAndDetectorWithSteepClimb() async throws {
        // Create a route: 0-500m flat (100m ele), 500m-1500m climb (100m -> 200m ele, 10% grade), 1500m-2000m flat (200m ele)
        var points: [RoutePoint] = []
        // Flat start
        for i in 0...5 {
            points.append(RoutePoint(
                coordinate: Coordinate(latitude: 37.0 + Double(i) * 0.001, longitude: -122.0),
                elevationMeters: 100.0,
                timestamp: Date(),
                cumulativeDistanceMeters: Double(i) * 100.0
            ))
        }
        // Climb: 500m to 1500m (1000m dist, +100m elevation -> 10% grade, score 10,000 >= 1200)
        for i in 1...10 {
            points.append(RoutePoint(
                coordinate: Coordinate(latitude: 37.005 + Double(i) * 0.001, longitude: -122.0),
                elevationMeters: 100.0 + Double(i) * 10.0,
                timestamp: Date(),
                cumulativeDistanceMeters: 500.0 + Double(i) * 100.0
            ))
        }
        // Flat finish
        for i in 1...5 {
            points.append(RoutePoint(
                coordinate: Coordinate(latitude: 37.015 + Double(i) * 0.001, longitude: -122.0),
                elevationMeters: 200.0,
                timestamp: Date(),
                cumulativeDistanceMeters: 1500.0 + Double(i) * 100.0
            ))
        }

        let route = Route(
            id: UUID(),
            metadata: RouteMetadata(name: "Hill Climb Route", sourceFileName: nil, createdAt: Date()),
            points: points,
            totalDistanceMeters: 2000.0
        )

        await engine.send(.loadRoute(route))
        try await Task.sleep(nanoseconds: 50_000_000)

        let initialSnap = engine.currentSnapshot
        XCTAssertEqual(initialSnap.state, .ready)
        XCTAssertEqual(initialSnap.climbs.count, 1)
        let climb = initialSnap.climbs[0]
        XCTAssertEqual(climb.climbIndex, 1)
        XCTAssertEqual(climb.startDistanceMeters, 500, accuracy: 1.0)
        XCTAssertEqual(climb.endDistanceMeters, 1600, accuracy: 1.0)
        XCTAssertEqual(climb.elevationGainMeters, 100, accuracy: 1.0)
        XCTAssertEqual(climb.category, .category4) // score > 8000 -> Cat 4

        // Advance into climb: 1000m (500m into climb)
        await engine.send(.processNavigation(ElevationProfileFactory.makeNavSnapshot(distanceAlongRoute: 1000)))

        let activeSnap = engine.currentSnapshot
        XCTAssertEqual(activeSnap.state, .activeClimb)
        guard let progress = activeSnap.activeClimbProgress else {
            XCTFail("Expected active climb progress")
            return
        }
        XCTAssertEqual(progress.distanceIntoClimbMeters, 500, accuracy: 1.0)

        // Summit and finish climb: 1700m
        await engine.send(.processNavigation(ElevationProfileFactory.makeNavSnapshot(distanceAlongRoute: 1700)))

        let completedSnap = engine.currentSnapshot
        XCTAssertEqual(completedSnap.state, .completedAllClimbs)
        XCTAssertEqual(completedSnap.completedClimbsCount, 1)
    }
}
