import XCTest
import CoreLocation
@testable import UltraNav

@MainActor
final class CyclingRideEngineTests: XCTestCase {
    func testRideEngineLifecycle() async throws {
        let fakeLocation = FakeLocationProvider()
        let fakeWorkout = FakeWorkoutProvider()
        let fakeSensors = FakeSensorProvider()
        let testClock = TestClock(initialTime: Date(timeIntervalSince1970: 1000))

        let rideEngine = RideEngine(
            locationService: fakeLocation,
            workoutService: fakeWorkout,
            sensorService: fakeSensors,
            clock: testClock
        )
        let engine = CyclingRideEngine(rideEngine: rideEngine)
        XCTAssertFalse(engine.isRiding)

        let route = SampleRoutes.alpineLoop
        try await rideEngine.startRide(route: route)
        XCTAssertTrue(engine.isRiding)
        XCTAssertFalse(engine.isPaused)
        XCTAssertEqual(engine.activeRoute?.name, route.name)

        engine.pauseRide()
        XCTAssertTrue(engine.isPaused)

        engine.resumeRide()
        XCTAssertFalse(engine.isPaused)

        try await rideEngine.finishRide()
        XCTAssertFalse(engine.isRiding)
    }

    func testHeartRateZones() {
        let engine = CyclingRideEngine()
        engine.maxHeartRate = 200

        XCTAssertEqual(engine.heartRateZone(for: 100), .zone1) // 50%
        XCTAssertEqual(engine.heartRateZone(for: 130), .zone2) // 65%
        XCTAssertEqual(engine.heartRateZone(for: 150), .zone3) // 75%
        XCTAssertEqual(engine.heartRateZone(for: 170), .zone4) // 85%
        XCTAssertEqual(engine.heartRateZone(for: 190), .zone5) // 95%
    }

    func testManualLapTrigger() async throws {
        let fakeLocation = FakeLocationProvider()
        let fakeWorkout = FakeWorkoutProvider()
        let fakeSensors = FakeSensorProvider()
        let testClock = TestClock(initialTime: Date(timeIntervalSince1970: 1000))

        let rideEngine = RideEngine(
            locationService: fakeLocation,
            workoutService: fakeWorkout,
            sensorService: fakeSensors,
            clock: testClock
        )
        let engine = CyclingRideEngine(rideEngine: rideEngine)

        try await rideEngine.startRide()
        
        // Advance clock and location to record distance and time
        testClock.advance(by: 60)
        let loc1 = LocationSample(
            coordinate: Coordinate(latitude: 37.7749, longitude: -122.4194),
            speedMetersPerSecond: 8.33,
            timestamp: testClock.now
        )
        await fakeLocation.send(.locationReceived(loc1))
        await fakeSensors.send(.sampleReceived(
            sensor: SensorIdentifier(rawValue: "hr-01"),
            sample: .heartRate(beatsPerMinute: 145, timestamp: testClock.now)
        ))

        engine.triggerManualLap()

        XCTAssertEqual(engine.laps.count, 1)
        XCTAssertEqual(engine.laps[0].lapNumber, 1)
        XCTAssertEqual(engine.currentLapDistance, 0)
        XCTAssertEqual(engine.currentLapDuration, 0)

        try await rideEngine.finishRide()
    }
}
