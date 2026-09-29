import XCTest
@testable import UltraNav

final class GPSProcessorTests: XCTestCase {
    private var processor: GPSProcessor!
    private var config: GPSProcessingConfiguration!

    override func setUp() {
        super.setUp()
        config = GPSProcessingConfiguration.outdoorCycling
        processor = GPSProcessor(configuration: config)
    }

    func testIgnoredWhenIdle() async {
        let sample = LocationSample(coordinate: Coordinate(latitude: 37.33, longitude: -122.01), timestamp: Date())
        let result = await processor.process(sample, receivedAt: Date())

        if case .ignored(let ignored) = result {
            XCTAssertEqual(ignored.reason, .notRecording)
        } else {
            XCTFail("Expected ignored result, got: \(result)")
        }
    }

    func testAcceptedWhenStarted() async {
        let t0 = Date(timeIntervalSince1970: 1700000000)
        await processor.send(.start(at: t0))

        let s1 = LocationSample(
            coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100),
            horizontalAccuracyMeters: 5.0,
            speedMetersPerSecond: 6.0,
            timestamp: t0
        )

        let r1 = await processor.process(s1, receivedAt: t0)

        guard case .accepted(let accepted1) = r1 else {
            XCTFail("Expected accepted sample, got: \(r1)")
            return
        }

        XCTAssertEqual(accepted1.quality, .excellent)
        XCTAssertEqual(accepted1.distanceIncrementMeters, 0.0)
        XCTAssertEqual(accepted1.totalDistanceMeters, 0.0)
        XCTAssertEqual(accepted1.sequence, 1)

        // Second moving sample 2 seconds later (~22m)
        let t1 = Date(timeIntervalSince1970: 1700000002)
        let s2 = LocationSample(
            coordinate: Coordinate(latitude: 37.3302, longitude: -122.0100),
            horizontalAccuracyMeters: 5.0,
            speedMetersPerSecond: 11.0,
            timestamp: t1
        )

        let r2 = await processor.process(s2, receivedAt: t1)

        guard case .accepted(let accepted2) = r2 else {
            XCTFail("Expected accepted sample 2, got: \(r2)")
            return
        }

        XCTAssertEqual(accepted2.sequence, 2)
        // 2 consecutive moving samples -> movementState becomes moving and accumulates distance!
        XCTAssertEqual(accepted2.movementState, .moving)
        XCTAssertGreaterThan(accepted2.distanceIncrementMeters, 20.0)
        XCTAssertGreaterThan(accepted2.totalDistanceMeters, 20.0)
    }

    func testPauseAndResumePreventsDistanceJump() async {
        let t0 = Date(timeIntervalSince1970: 1700000000)
        await processor.send(.start(at: t0))

        let s1 = LocationSample(coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100), horizontalAccuracyMeters: 5.0, speedMetersPerSecond: 10.0, timestamp: t0)
        _ = await processor.process(s1, receivedAt: t0)

        let t1 = Date(timeIntervalSince1970: 1700000002)
        let s2 = LocationSample(coordinate: Coordinate(latitude: 37.3302, longitude: -122.0100), horizontalAccuracyMeters: 5.0, speedMetersPerSecond: 10.0, timestamp: t1)
        _ = await processor.process(s2, receivedAt: t1)

        let snapBefore = await processor.snapshot()
        let distBefore = snapBefore.totalDistanceMeters

        // Pause ride
        let tPause = Date(timeIntervalSince1970: 1700000005)
        await processor.send(.pause(at: tPause))

        // Sample while paused is rejected
        let sPaused = LocationSample(coordinate: Coordinate(latitude: 37.3303, longitude: -122.0100), horizontalAccuracyMeters: 5.0, timestamp: tPause)
        let rPaused = await processor.process(sPaused, receivedAt: tPause)
        if case .rejected(let rej) = rPaused {
            XCTAssertEqual(rej.reason, .processorPaused)
        } else {
            XCTFail("Expected processorPaused rejection, got: \(rPaused)")
        }

        // Resume ride 100 seconds later at a completely different coordinate (e.g. rider walked/transported)
        let tResume = Date(timeIntervalSince1970: 1700000100)
        await processor.send(.resume(at: tResume))

        let sResume1 = LocationSample(
            coordinate: Coordinate(latitude: 37.3500, longitude: -122.0100), // ~2.2km away!
            horizontalAccuracyMeters: 5.0,
            speedMetersPerSecond: 10.0,
            timestamp: tResume
        )

        let rResume1 = await processor.process(sResume1, receivedAt: tResume)

        guard case .accepted(let accResume) = rResume1 else {
            XCTFail("Expected accepted first resume sample, got: \(rResume1)")
            return
        }

        // Crucial guarantee: first post-resume sample must add ZERO distance (no 2.2km jump!)
        XCTAssertEqual(accResume.distanceIncrementMeters, 0.0)
        XCTAssertEqual(accResume.totalDistanceMeters, distBefore)
    }

    func testOutageRecoveryPreventsBridgeJump() async {
        let t0 = Date(timeIntervalSince1970: 1700000000)
        await processor.send(.start(at: t0))

        let s1 = LocationSample(coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100), horizontalAccuracyMeters: 5.0, timestamp: t0)
        _ = await processor.process(s1, receivedAt: t0)

        // GPS signal loss (tunnel / outage)
        let tOutage = Date(timeIntervalSince1970: 1700000010)
        await processor.send(.locationUnavailable(at: tOutage))

        // Signal regained 60 seconds later at tunnel exit
        let tRecover = Date(timeIntervalSince1970: 1700000070)
        await processor.send(.locationAvailable(at: tRecover))

        let sExit = LocationSample(
            coordinate: Coordinate(latitude: 37.3400, longitude: -122.0100), // 1.1km away
            horizontalAccuracyMeters: 5.0,
            speedMetersPerSecond: 8.0,
            timestamp: tRecover
        )

        let rExit = await processor.process(sExit, receivedAt: tRecover)

        guard case .accepted(let accExit) = rExit else {
            XCTFail("Expected accepted recovery sample, got: \(rExit)")
            return
        }

        // Outage recovery must NOT bridge false straight line distance
        XCTAssertEqual(accExit.distanceIncrementMeters, 0.0)
        XCTAssertEqual(accExit.totalDistanceMeters, 0.0)
    }
}
