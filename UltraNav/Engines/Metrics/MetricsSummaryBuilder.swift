import Foundation

struct MetricsSummaryBuilder: Sendable {
    private let averageCalculator: any AverageCalculating
    private let maximumCalculator: any MaximumCalculating

    init(
        averageCalculator: any AverageCalculating = SimpleAverageCalculator(),
        maximumCalculator: any MaximumCalculating = SimpleMaximumCalculator()
    ) {
        self.averageCalculator = averageCalculator
        self.maximumCalculator = maximumCalculator
    }

    func makeSnapshot(
        store: MetricStore,
        now: Date
    ) -> MetricsSnapshot {
        let speedMetric: CurrentMetric<Double>?
        if let obs = store.latestSpeedObservation, case .speed(let mps) = obs.value {
            speedMetric = CurrentMetric(
                value: mps,
                source: obs.source,
                timestamp: obs.timestamp,
                freshness: MetricFreshness.freshness(for: obs.timestamp, now: now)
            )
        } else {
            speedMetric = nil
        }

        let hrMetric: CurrentMetric<Int>?
        if let obs = store.latestHeartRateObservation, case .heartRate(let bpm) = obs.value {
            hrMetric = CurrentMetric(
                value: bpm,
                source: obs.source,
                timestamp: obs.timestamp,
                freshness: MetricFreshness.freshness(for: obs.timestamp, now: now)
            )
        } else {
            hrMetric = nil
        }

        let cadenceMetric: CurrentMetric<Double>?
        if let obs = store.latestCadenceObservation, case .cadence(let rpm) = obs.value {
            cadenceMetric = CurrentMetric(
                value: rpm,
                source: obs.source,
                timestamp: obs.timestamp,
                freshness: MetricFreshness.freshness(for: obs.timestamp, now: now)
            )
        } else {
            cadenceMetric = nil
        }

        let powerMetric: CurrentMetric<Int>?
        if let obs = store.latestPowerObservation, case .power(let watts) = obs.value {
            powerMetric = CurrentMetric(
                value: watts,
                source: obs.source,
                timestamp: obs.timestamp,
                freshness: MetricFreshness.freshness(for: obs.timestamp, now: now)
            )
        } else {
            powerMetric = nil
        }

        let distanceMetric: CurrentMetric<Double>?
        if let obs = store.latestDistanceObservation, case .distance(let meters) = obs.value {
            distanceMetric = CurrentMetric(
                value: meters,
                source: obs.source,
                timestamp: obs.timestamp,
                freshness: MetricFreshness.freshness(for: obs.timestamp, now: now)
            )
        } else {
            distanceMetric = nil
        }

        let altitudeMetric: CurrentMetric<Double>?
        if let obs = store.latestAltitudeObservation, case .altitude(let meters) = obs.value {
            altitudeMetric = CurrentMetric(
                value: meters,
                source: obs.source,
                timestamp: obs.timestamp,
                freshness: MetricFreshness.freshness(for: obs.timestamp, now: now)
            )
        } else {
            altitudeMetric = nil
        }

        let energyMetric: CurrentMetric<Double>?
        if let obs = store.latestEnergyObservation, case .energy(let kcal) = obs.value {
            energyMetric = CurrentMetric(
                value: kcal,
                source: obs.source,
                timestamp: obs.timestamp,
                freshness: MetricFreshness.freshness(for: obs.timestamp, now: now)
            )
        } else {
            energyMetric = nil
        }

        let speedSamples = store.speedBuffer.observations.compactMap { obs -> Double? in
            if case .speed(let mps) = obs.value { return mps }
            return nil
        }
        let avgSpeed = averageCalculator.calculateAverage(samples: speedSamples)
        let maxSpeed = maximumCalculator.calculateMaximum(samples: speedSamples)

        let hrSamples = store.heartRateBuffer.observations.compactMap { obs -> Double? in
            if case .heartRate(let bpm) = obs.value { return Double(bpm) }
            return nil
        }
        let avgHR = averageCalculator.calculateAverage(samples: hrSamples).map { Int($0.rounded()) }
        let maxHR = maximumCalculator.calculateMaximum(samples: hrSamples).map { Int($0.rounded()) }

        let cadenceSamples = store.cadenceBuffer.observations.compactMap { obs -> Double? in
            if case .cadence(let rpm) = obs.value { return rpm }
            return nil
        }
        let avgCadence = averageCalculator.calculateAverage(samples: cadenceSamples)

        let powerSamples = store.powerBuffer.observations.compactMap { obs -> Double? in
            if case .power(let watts) = obs.value { return Double(watts) }
            return nil
        }
        let avgPower = averageCalculator.calculateAverage(samples: powerSamples).map { Int($0.rounded()) }
        let maxPower = maximumCalculator.calculateMaximum(samples: powerSamples).map { Int($0.rounded()) }

        let availability = MetricAvailability(
            hasSpeed: speedMetric != nil && speedMetric?.freshness != .expired,
            hasHeartRate: hrMetric != nil && hrMetric?.freshness != .expired,
            hasCadence: cadenceMetric != nil && cadenceMetric?.freshness != .expired,
            hasPower: powerMetric != nil && powerMetric?.freshness != .expired,
            hasDistance: distanceMetric != nil,
            hasAltitude: altitudeMetric != nil,
            hasEnergy: energyMetric != nil
        )

        return MetricsSnapshot(
            speed: speedMetric,
            heartRate: hrMetric,
            cadence: cadenceMetric,
            power: powerMetric,
            distance: distanceMetric,
            altitude: altitudeMetric,
            energy: energyMetric,
            averageSpeedMetersPerSecond: avgSpeed,
            maxSpeedMetersPerSecond: maxSpeed,
            averageHeartRateBeatsPerMinute: avgHR,
            maxHeartRateBeatsPerMinute: maxHR,
            averageCadenceRevolutionsPerMinute: avgCadence,
            averagePowerWatts: avgPower,
            maxPowerWatts: maxPower,
            normalizedPowerWatts: nil,
            totalKilocalories: store.totalEnergyKilocalories > 0 ? store.totalEnergyKilocalories : nil,
            availability: availability,
            timestamp: now
        )
    }
}
