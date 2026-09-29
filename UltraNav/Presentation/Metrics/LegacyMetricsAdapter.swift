import Foundation

@MainActor
final class LegacyMetricsAdapter {
    private let engine: any MetricsEngineProviding

    init(engine: any MetricsEngineProviding) {
        self.engine = engine
    }

    var currentRideMetrics: RideMetrics {
        let snap = engine.currentSnapshot
        return RideMetrics(
            currentSpeedMetersPerSecond: snap.speed?.value,
            distanceMeters: snap.distance?.value ?? 0,
            heartRateBeatsPerMinute: snap.heartRate?.value,
            cadenceRevolutionsPerMinute: snap.cadence?.value,
            powerWatts: snap.power?.value,
            altitudeMeters: snap.altitude?.value
        )
    }
}
