import XCTest
import CoreLocation
@testable import UltraNav

@MainActor
final class CyclingRideEngineTests: XCTestCase {
    func testRideEngineLifecycle() {
        let engine = CyclingRideEngine()
        XCTAssertFalse(engine.isRiding)

        let route = SampleRoutes.alpineLoop
        engine.startRide(route: route)
        XCTAssertTrue(engine.isRiding)
        XCTAssertFalse(engine.isPaused)
        XCTAssertEqual(engine.activeRoute?.name, route.name)

        engine.pauseRide()
        XCTAssertTrue(engine.isPaused)

        engine.resumeRide()
        XCTAssertFalse(engine.isPaused)

        engine.finishRide()
        XCTAssertFalse(engine.isRiding)
    }

    func testHeartRateZones() {
        let engine = CyclingRideEngine()
        engine.maxHeartRate = 200

        engine.heartRate = 100 // 50%
        XCTAssertEqual(engine.heartRateZone, .zone1)

        engine.heartRate = 130 // 65%
        XCTAssertEqual(engine.heartRateZone, .zone2)

        engine.heartRate = 150 // 75%
        XCTAssertEqual(engine.heartRateZone, .zone3)

        engine.heartRate = 170 // 85%
        XCTAssertEqual(engine.heartRateZone, .zone4)

        engine.heartRate = 190 // 95%
        XCTAssertEqual(engine.heartRateZone, .zone5)
    }

    func testManualLapTrigger() {
        let engine = CyclingRideEngine()
        engine.startRide()
        engine.currentLapDuration = 60
        engine.currentLapDistance = 500
        engine.heartRate = 145

        engine.triggerManualLap()

        XCTAssertEqual(engine.laps.count, 1)
        XCTAssertEqual(engine.laps[0].lapNumber, 1)
        XCTAssertEqual(engine.laps[0].duration, 60)
        XCTAssertEqual(engine.laps[0].distance, 500)
        XCTAssertEqual(engine.laps[0].avgHeartRate, 145)
        XCTAssertEqual(engine.currentLapDistance, 0)
        XCTAssertEqual(engine.currentLapDuration, 0)

        engine.finishRide()
    }
}
