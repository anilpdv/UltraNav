import Foundation

public struct StandardDurationFormatter: DurationFormatting, Sendable {
    public init() {}

    public func formatDuration(seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds.rounded(.down)))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let remainingSeconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

public struct StandardSpeedFormatter: SpeedFormatting, Sendable {
    public init() {}

    public func formatSpeed(
        metersPerSecond: Double,
        preferences: UnitPreferences
    ) -> MetricDisplayValue {
        guard metersPerSecond.isFinite && metersPerSecond >= 0 else {
            return .unavailable(unit: preferences.distanceSystem == .metric ? "km/h" : "mph", label: "Speed")
        }

        switch preferences.distanceSystem {
        case .metric:
            let kmh = metersPerSecond * 3.6
            let text = String(format: "%.1f", kmh)
            return MetricDisplayValue(
                primaryText: text,
                unitText: "km/h",
                availability: .available,
                accessibilityLabel: "Speed",
                accessibilityValue: "\(text) kilometers per hour"
            )
        case .imperial:
            let mph = metersPerSecond * 2.23694
            let text = String(format: "%.1f", mph)
            return MetricDisplayValue(
                primaryText: text,
                unitText: "mph",
                availability: .available,
                accessibilityLabel: "Speed",
                accessibilityValue: "\(text) miles per hour"
            )
        }
    }
}

public struct StandardDistanceFormatter: DistanceFormatting, Sendable {
    public init() {}

    public func formatDistance(
        meters: Double,
        preferences: UnitPreferences
    ) -> MetricDisplayValue {
        guard meters.isFinite && meters >= 0 else {
            return .unavailable(unit: preferences.distanceSystem == .metric ? "km" : "mi", label: "Distance")
        }

        switch preferences.distanceSystem {
        case .metric:
            if meters < 1000 {
                let text = "\(Int(meters.rounded()))"
                return MetricDisplayValue(
                    primaryText: text,
                    unitText: "m",
                    availability: .available,
                    accessibilityLabel: "Distance",
                    accessibilityValue: "\(text) meters"
                )
            } else {
                let km = meters / 1000.0
                let text = String(format: "%.1f", km)
                return MetricDisplayValue(
                    primaryText: text,
                    unitText: "km",
                    availability: .available,
                    accessibilityLabel: "Distance",
                    accessibilityValue: "\(text) kilometers"
                )
            }
        case .imperial:
            let feet = meters * 3.28084
            if feet < 1000 {
                let text = "\(Int(feet.rounded()))"
                return MetricDisplayValue(
                    primaryText: text,
                    unitText: "ft",
                    availability: .available,
                    accessibilityLabel: "Distance",
                    accessibilityValue: "\(text) feet"
                )
            } else {
                let miles = meters / 1609.344
                let text = String(format: "%.1f", miles)
                return MetricDisplayValue(
                    primaryText: text,
                    unitText: "mi",
                    availability: .available,
                    accessibilityLabel: "Distance",
                    accessibilityValue: "\(text) miles"
                )
            }
        }
    }
}

public struct StandardElevationFormatter: ElevationFormatting, Sendable {
    public init() {}

    public func formatElevation(
        meters: Double,
        preferences: UnitPreferences
    ) -> MetricDisplayValue {
        guard meters.isFinite else {
            return .unavailable(unit: preferences.distanceSystem == .metric ? "m" : "ft", label: "Elevation")
        }

        switch preferences.distanceSystem {
        case .metric:
            let text = "\(Int(meters.rounded()))"
            return MetricDisplayValue(
                primaryText: text,
                unitText: "m",
                availability: .available,
                accessibilityLabel: "Elevation",
                accessibilityValue: "\(text) meters"
            )
        case .imperial:
            let feet = meters * 3.28084
            let text = "\(Int(feet.rounded()))"
            return MetricDisplayValue(
                primaryText: text,
                unitText: "ft",
                availability: .available,
                accessibilityLabel: "Elevation",
                accessibilityValue: "\(text) feet"
            )
        }
    }
}

public struct StandardGradientFormatter: GradientFormatting, Sendable {
    public init() {}

    public func formatGradient(
        ratio: Double
    ) -> MetricDisplayValue {
        guard ratio.isFinite else {
            return .unavailable(unit: "%", label: "Gradient")
        }

        let percent = ratio * 100.0
        let text = String(format: "%.1f", percent)
        return MetricDisplayValue(
            primaryText: text,
            unitText: "%",
            availability: .available,
            accessibilityLabel: "Gradient",
            accessibilityValue: "\(text) percent"
        )
    }
}
