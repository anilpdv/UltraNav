import Foundation

public struct MetricsViewStateMapper: Sendable {
    private let speedFormatter: any SpeedFormatting
    private let distanceFormatter: any DistanceFormatting
    private let elevationFormatter: any ElevationFormatting
    private let durationFormatter: any DurationFormatting

    public init(
        speedFormatter: any SpeedFormatting = StandardSpeedFormatter(),
        distanceFormatter: any DistanceFormatting = StandardDistanceFormatter(),
        elevationFormatter: any ElevationFormatting = StandardElevationFormatter(),
        durationFormatter: any DurationFormatting = StandardDurationFormatter()
    ) {
        self.speedFormatter = speedFormatter
        self.distanceFormatter = distanceFormatter
        self.elevationFormatter = elevationFormatter
        self.durationFormatter = durationFormatter
    }

    func map(
        metrics: MetricsSnapshot,
        ride: RideSnapshot?,
        preferences: UnitPreferences = .default
    ) -> MetricsViewState {
        let isRecording = ride?.state.hasActiveRideSession ?? false
        let isPaused = ride?.state == .paused

        var tiles: [MetricTileState] = []

        // 1. Current Speed
        let speedVal: MetricDisplayValue
        if let speedObs = metrics.speed {
            let base = speedFormatter.formatSpeed(metersPerSecond: speedObs.value, preferences: preferences)
            speedVal = speedObs.freshness == .stale ? .stale(primaryText: base.primaryText, unit: base.unitText, label: "Speed") : base
        } else {
            speedVal = .unavailable(unit: preferences.distanceSystem == .metric ? "km/h" : "mph", label: "Speed")
        }
        tiles.append(MetricTileState(id: .speed, title: "SPEED", value: speedVal, emphasis: .primary))

        // 2. Average Speed
        let avgSpeedVal: MetricDisplayValue
        if let avgSpeed = metrics.averageSpeedMetersPerSecond {
            avgSpeedVal = speedFormatter.formatSpeed(metersPerSecond: avgSpeed, preferences: preferences)
        } else {
            avgSpeedVal = .unavailable(unit: preferences.distanceSystem == .metric ? "km/h" : "mph", label: "Average Speed")
        }
        tiles.append(MetricTileState(id: .averageSpeed, title: "AVG SPEED", value: avgSpeedVal))

        // 3. Heart Rate
        let hrVal: MetricDisplayValue
        if let hrObs = metrics.heartRate {
            let hrText = "\(hrObs.value)"
            hrVal = MetricDisplayValue(
                primaryText: hrText,
                unitText: "bpm",
                availability: hrObs.freshness == .stale ? .stale : .available,
                accessibilityLabel: "Heart Rate",
                accessibilityValue: "\(hrText) beats per minute"
            )
        } else {
            hrVal = .unavailable(unit: "bpm", label: "Heart Rate")
        }
        tiles.append(MetricTileState(id: .heartRate, title: "HEART RATE", value: hrVal))

        // 4. Power
        let powerVal: MetricDisplayValue
        if let pwrObs = metrics.power {
            let pwrText = "\(pwrObs.value)"
            powerVal = MetricDisplayValue(
                primaryText: pwrText,
                unitText: "W",
                availability: pwrObs.freshness == .stale ? .stale : .available,
                accessibilityLabel: "Power",
                accessibilityValue: "\(pwrText) Watts"
            )
        } else {
            powerVal = .unavailable(unit: "W", label: "Power")
        }
        tiles.append(MetricTileState(id: .power, title: "POWER", value: powerVal))

        // 5. Cadence
        let cadVal: MetricDisplayValue
        if let cadObs = metrics.cadence {
            let cadText = "\(Int(cadObs.value.rounded()))"
            cadVal = MetricDisplayValue(
                primaryText: cadText,
                unitText: "rpm",
                availability: cadObs.freshness == .stale ? .stale : .available,
                accessibilityLabel: "Cadence",
                accessibilityValue: "\(cadText) revolutions per minute"
            )
        } else {
            cadVal = .unavailable(unit: "rpm", label: "Cadence")
        }
        tiles.append(MetricTileState(id: .cadence, title: "CADENCE", value: cadVal))

        // 6. Distance
        let distVal: MetricDisplayValue
        if let distObs = metrics.distance {
            distVal = distanceFormatter.formatDistance(meters: distObs.value, preferences: preferences)
        } else {
            distVal = distanceFormatter.formatDistance(meters: ride?.metrics.distanceMeters ?? 0, preferences: preferences)
        }
        tiles.append(MetricTileState(id: .distance, title: "DISTANCE", value: distVal))

        // 7. Elapsed / Moving Time
        if let ride = ride {
            let elapsedStr = durationFormatter.formatDuration(seconds: ride.elapsedTimeSeconds)
            let elapsedVal = MetricDisplayValue(
                primaryText: elapsedStr,
                unitText: "",
                availability: .available,
                accessibilityLabel: "Elapsed Time",
                accessibilityValue: elapsedStr
            )
            tiles.append(MetricTileState(id: .elapsedTime, title: "ELAPSED", value: elapsedVal))

            let movingStr = durationFormatter.formatDuration(seconds: ride.movingTimeSeconds)
            let movingVal = MetricDisplayValue(
                primaryText: movingStr,
                unitText: "",
                availability: .available,
                accessibilityLabel: "Moving Time",
                accessibilityValue: movingStr
            )
            tiles.append(MetricTileState(id: .movingTime, title: "TIME", value: movingVal))
        }

        // 8. Altitude
        let altVal: MetricDisplayValue
        if let altObs = metrics.altitude {
            altVal = elevationFormatter.formatElevation(meters: altObs.value, preferences: preferences)
        } else {
            altVal = .unavailable(unit: preferences.distanceSystem == .metric ? "m" : "ft", label: "Altitude")
        }
        tiles.append(MetricTileState(id: .altitude, title: "ALTITUDE", value: altVal))

        return MetricsViewState(
            tiles: tiles,
            isRecording: isRecording,
            isPaused: isPaused
        )
    }
}
