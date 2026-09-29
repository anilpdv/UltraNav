import Foundation
import Testing
@testable import UltraNav

@Suite("LapEngine Tests")
struct LapEngineTests {
    @Test("Starts ride and creates manual laps with immutable summaries")
    func testManualLapCreation() {
        var engine = LapEngine()
        let t0 = Date(timeIntervalSince1970: 1000)

        engine.startRide(at: t0, distanceMeters: 0)
        #expect(engine.currentLapNumber == 1)
        #expect(engine.completedLaps.isEmpty)

        // Advance 30 seconds and 200m with 200W power and 8m/s speed
        let t1 = t0.addingTimeInterval(30)
        let speedObs = MetricObservation(kind: .speed, value: .speedMetersPerSecond(8.0), source: .gps, measuredAt: t1)
        let powerObs = MetricObservation(kind: .power, value: .powerWatts(200.0), source: .gps, measuredAt: t1)
        engine.consume(observation: speedObs, at: t1, isPaused: false, currentSpeed: 8.0)
        engine.consume(observation: powerObs, at: t1, isPaused: false, currentSpeed: 8.0)

        let lap1 = engine.createLap(trigger: .manual, at: t1, distanceMeters: 200)
        #expect(lap1 != nil)
        #expect(lap1?.number == 1)
        #expect(lap1?.summary.distanceMeters == 200)
        #expect(engine.currentLapNumber == 2)
        #expect(engine.completedLaps.count == 1)

        // Advance another 30 seconds to t2 and 500m total
        let t2 = t1.addingTimeInterval(30)
        let lap2 = engine.createLap(trigger: .manual, at: t2, distanceMeters: 500)
        #expect(lap2 != nil)
        #expect(lap2?.number == 2)
        #expect(lap2?.summary.distanceMeters == 300) // 500 - 200
        #expect(engine.currentLapNumber == 3)
        #expect(engine.completedLaps.count == 2)
    }
}

@Suite("MetricsIntegration Tests")
struct MetricsIntegrationTests {
    @Test("Full ride lifecycle with GPS, Bluetooth sensors, and pause/resume")
    @MainActor
    func testFullRideLifecycle() async {
        let clock = TestClock()
        let engine = MetricsEngine(clock: clock)

        let t0 = Date(timeIntervalSince1970: 1000)
        clock.set(t0)

        // 1. Start Ride
        await engine.send(.start(at: t0))
        #expect(engine.state == .active)

        // 2. Feed GPS and BLE Power
        let t1 = t0.addingTimeInterval(10)
        clock.set(t1)
        engine.consume(sensor: SensorIdentifier(rawValue: "pwr-1"), sample: .power(watts: 250, timestamp: t1))
        engine.consume(gps: GPSAcceptedSample(
            sample: LocationSampleFactory.make(
                latitude: 37.77,
                longitude: -122.41,
                altitudeMeters: 50,
                horizontalAccuracyMeters: 5,
                speedMetersPerSecond: 10.0,
                timestamp: t1
            ),
            quality: .good,
            selectedSpeedMetersPerSecond: 10.0,
            movementState: .moving,
            distanceIncrementMeters: 100.0,
            totalDistanceMeters: 100.0,
            sequence: 1
        ))

        let snap1 = engine.currentSnapshot
        #expect(snap1.speed?.value == 10.0)
        #expect(snap1.power?.value == 250)
        #expect(snap1.distance?.value == 100.0)

        // 3. Pause
        let t2 = t1.addingTimeInterval(5)
        clock.set(t2)
        await engine.send(.pause(at: t2))
        #expect(engine.state == .paused)

        // 4. Resume
        let t3 = t2.addingTimeInterval(10)
        clock.set(t3)
        await engine.send(.resume(at: t3))
        #expect(engine.state == .active)

        // 5. Finish
        let t4 = t3.addingTimeInterval(20)
        clock.set(t4)
        await engine.send(.finish(at: t4))
        #expect(engine.state == .stopped)
        #expect(engine.currentSnapshot.summary != nil)
        #expect(engine.currentSnapshot.summary?.distanceMeters == 100.0)
    }
}
