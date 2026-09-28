import XCTest
import CoreLocation
@testable import UltraNav

@MainActor
final class CyclingRideEngineTests: XCTestCase {
    func testRideEngineLifecycle() async throws {
        let fakeLocation = FakeLocationProvider()
        let fakeWorkout = FakeWorkoutProvider()
        let fakeSensors = FakeSensorProvider()
        let testClock = TestClock(now: Date(timeIntervalSince1970: 1000))

        await fakeLocation.setStubbedAuthorizationStatus(.authorized)
        await fakeWorkout.setStubbedAuthorizationStatus(.authorized)

        let rideEngine = RideEngine(
            location: fakeLocation,
            workout: fakeWorkout,
            sensors: fakeSensors,
            clock: testClock
        )
        let engine = CyclingRideEngine(rideEngine: rideEngine)
        XCTAssertFalse(engine.isRiding)

        let route = SampleRoutes.alpineLoop
        await rideEngine.send(.prepare)
        await rideEngine.send(.start)
        engine.activeRoute = route

        XCTAssertTrue(engine.isRiding)
        XCTAssertFalse(engine.isPaused)
        XCTAssertEqual(engine.activeRoute?.name, route.name)

        await rideEngine.send(.pause)
        XCTAssertTrue(engine.isPaused)

        await rideEngine.send(.resume)
        XCTAssertFalse(engine.isPaused)

        await rideEngine.send(.finish)
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
        let testClock = TestClock(now: Date(timeIntervalSince1970: 1000))

        await fakeLocation.setStubbedAuthorizationStatus(.authorized)
        await fakeWorkout.setStubbedAuthorizationStatus(.authorized)

        let rideEngine = RideEngine(
            location: fakeLocation,
            workout: fakeWorkout,
            sensors: fakeSensors,
            clock: testClock
        )
        let engine = CyclingRideEngine(rideEngine: rideEngine)

        await rideEngine.send(.prepare)
        await rideEngine.send(.start)

        engine.triggerManualLap()

        XCTAssertEqual(engine.laps.count, 1)
        XCTAssertEqual(engine.laps[0].lapNumber, 1)
        XCTAssertEqual(engine.currentLapDistance, 0)
        XCTAssertEqual(engine.currentLapDuration, 0)

        await rideEngine.send(.finish)
    }
}
