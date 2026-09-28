import Foundation

struct RideMetricState: Equatable, Sendable {
    var latestLocation: LocationSample?
    var distanceMeters: Double = 0
    var currentSpeedMetersPerSecond: Double?
    var heartRateBeatsPerMinute: Int?
    var cadenceRevolutionsPerMinute: Double?
    var powerWatts: Int?
    var altitudeMeters: Double?

    mutating func reset() {
        self = RideMetricState()
    }

    mutating func consume(location sample: LocationSample) {
        latestLocation = sample
        currentSpeedMetersPerSecond = sample.speedMetersPerSecond
        altitudeMeters = sample.altitudeMeters
    }

    mutating func consumeHeartRate(_ bpm: Int) {
        heartRateBeatsPerMinute = bpm
    }

    mutating func consumeDistance(_ meters: Double) {
        distanceMeters = max(0, meters)
    }

    mutating func consume(workout metric: WorkoutMetric) {
        // TODO(PHASE-9): Replace latest-event-wins behavior with explicit source priority and freshness rules.
        switch metric {
        case .heartRate(let beatsPerMinute, _):
            heartRateBeatsPerMinute = Int(beatsPerMinute.rounded())

        case .activeEnergy:
            break

        case .cyclingDistance(let meters, _):
            distanceMeters = max(0, meters)
        }
    }

    mutating func consume(sensor sample: SensorSample) {
        // TODO(PHASE-9): Replace latest-event-wins behavior with explicit source priority and freshness rules.
        switch sample {
        case .heartRate(let beatsPerMinute, _):
            heartRateBeatsPerMinute = beatsPerMinute

        case .power(let watts, _):
            powerWatts = watts

        case .cadence(let revolutionsPerMinute, _):
            cadenceRevolutionsPerMinute = revolutionsPerMinute

        case .speed(let metersPerSecond, _):
            currentSpeedMetersPerSecond = metersPerSecond
        }
    }
}
