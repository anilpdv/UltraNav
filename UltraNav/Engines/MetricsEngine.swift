import Foundation

/// Pure calculation engine for speed, distance, laps, cadence, power, and time.
@MainActor
final class MetricsEngine {
    private(set) var metrics: RideMetrics = .empty
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var movingTime: TimeInterval = 0

    var isAutoPauseEnabled: Bool = true
    var autoLapDistanceMeters: Double = 5000.0

    private(set) var totalDistanceMeters: Double = 0
    private(set) var currentSpeedMetersPerSecond: Double?
    private(set) var maxSpeedMetersPerSecond: Double = 0
    private(set) var heartRate: Int?
    private(set) var cadenceRPM: Double?
    private(set) var powerWatts: Int?
    private(set) var currentAltitudeMeters: Double?
    private(set) var activeCalories: Int = 0

    private(set) var laps: [LapRecord] = []
    private(set) var currentLapDuration: TimeInterval = 0
    private(set) var currentLapDistance: Double = 0

    private var lapStartTime: Date = Date()
    private var lapStartDistance: Double = 0
    private var lastLocationSample: LocationSample?

    init() {}

    func reset(at date: Date = Date()) {
        self.metrics = .empty
        self.elapsedTime = 0
        self.movingTime = 0
        self.totalDistanceMeters = 0
        self.currentSpeedMetersPerSecond = nil
        self.maxSpeedMetersPerSecond = 0
        self.heartRate = nil
        self.cadenceRPM = nil
        self.powerWatts = nil
        self.currentAltitudeMeters = nil
        self.activeCalories = 0
        self.laps = []
        self.currentLapDuration = 0
        self.currentLapDistance = 0
        self.lapStartTime = date
        self.lapStartDistance = 0
        self.lastLocationSample = nil
    }

    func updateTimerTick() {
        elapsedTime += 1

        let currentSpeed = currentSpeedMetersPerSecond ?? 0
        if isAutoPauseEnabled && currentSpeed < 0.4 && elapsedTime > 5 {
            // Stationary (< ~1.5 km/h) - do not increment moving time
        } else {
            movingTime += 1
        }

        currentLapDuration += 1

        if currentLapDistance >= autoLapDistanceMeters {
            triggerLap()
        }

        recalculateMetrics()
    }

    func update(location: LocationSample) {
        if let spd = location.speedMetersPerSecond {
            currentSpeedMetersPerSecond = spd
            if spd > maxSpeedMetersPerSecond {
                maxSpeedMetersPerSecond = spd
            }
        }

        if let alt = location.altitudeMeters {
            currentAltitudeMeters = alt
        }

        if let last = lastLocationSample {
            let dist = location.coordinate.distance(to: last.coordinate)
            if dist > 1.5 && dist < 150.0 {
                totalDistanceMeters += dist
                currentLapDistance += dist
            }
        }
        self.lastLocationSample = location
        recalculateMetrics()
    }

    func updateSensors(
        speedMetersPerSecond: Double? = nil,
        heartRate: Int? = nil,
        cadenceRPM: Double? = nil,
        powerWatts: Int? = nil,
        activeCalories: Int? = nil
    ) {
        if let speedMetersPerSecond {
            self.currentSpeedMetersPerSecond = speedMetersPerSecond
            if speedMetersPerSecond > maxSpeedMetersPerSecond {
                maxSpeedMetersPerSecond = speedMetersPerSecond
            }
        }
        if let heartRate, heartRate > 0 {
            self.heartRate = heartRate
        }
        if let cadenceRPM, cadenceRPM > 0 {
            self.cadenceRPM = cadenceRPM
        }
        if let powerWatts, powerWatts >= 0 {
            self.powerWatts = powerWatts
        }
        if let activeCalories {
            self.activeCalories = activeCalories
        }
        recalculateMetrics()
    }

    private func recalculateMetrics() {
        metrics = RideMetrics(
            currentSpeedMetersPerSecond: currentSpeedMetersPerSecond,
            distanceMeters: totalDistanceMeters,
            heartRateBeatsPerMinute: heartRate,
            cadenceRevolutionsPerMinute: cadenceRPM,
            powerWatts: powerWatts,
            altitudeMeters: currentAltitudeMeters
        )
    }

    @discardableResult
    func triggerLap(at date: Date = Date()) -> LapRecord {
        let lapNum = laps.count + 1
        let duration = currentLapDuration
        let dist = currentLapDistance
        let avgSpd = duration > 0 ? (dist / duration) * 3.6 : 0

        let lap = LapRecord(
            lapNumber: lapNum,
            duration: duration,
            distance: dist,
            avgSpeedKmh: avgSpd,
            avgHeartRate: heartRate ?? 0,
            avgPower: powerWatts ?? 0
        )
        laps.append(lap)

        currentLapDuration = 0
        currentLapDistance = 0
        lapStartTime = date
        lapStartDistance = totalDistanceMeters

        return lap
    }
}
