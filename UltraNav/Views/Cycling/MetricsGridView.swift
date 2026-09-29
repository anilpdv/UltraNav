import SwiftUI

/// Wahoo & Garmin style high-contrast sunlight-readable cycling computer metrics matrix.
public struct MetricsGridView: View {
    @Environment(MetricsViewModel.self) private var metricsViewModel

    public init() {}

    public var body: some View {
        let state = metricsViewModel.state

        VStack(spacing: 4) {
            // Row 1: Primary Speed (Big Numbers) & Average Speed
            let speedTile = state.tile(for: .speed)
            let avgSpeedTile = state.tile(for: .averageSpeed)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(speedTile?.title ?? "SPEED")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(speedTile?.value.primaryText ?? "--.-")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(speedTile?.value.availability == .stale ? .gray : .white)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(speedTile?.value.accessibilityLabel ?? "Speed")
                .accessibilityValue(speedTile?.value.accessibilityValue ?? "Unavailable")

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 0) {
                    Text(avgSpeedTile?.title ?? "AVG")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(avgSpeedTile?.value.primaryText ?? "--.-")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.cyan)
                    Text(avgSpeedTile?.value.unitText ?? "km/h")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(avgSpeedTile?.value.accessibilityLabel ?? "Average Speed")
                .accessibilityValue(avgSpeedTile?.value.accessibilityValue ?? "Unavailable")
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))

            // Row 2: Heart Rate + Zone & Power / Cadence
            let hrTile = state.tile(for: .heartRate)
            let powerTile = state.tile(for: .power)
            let cadenceTile = state.tile(for: .cadence)

            HStack(spacing: 4) {
                // Heart Rate Box
                VStack(alignment: .leading, spacing: 1) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.red)
                        Text(hrTile?.title ?? "HEART RATE")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(hrTile?.value.primaryText ?? "--")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(hrTile?.value.availability == .available ? .red : .gray)
                        Text(hrTile?.value.unitText ?? "bpm")
                            .font(.system(size: 7))
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(hrTile?.value.accessibilityLabel ?? "Heart Rate")
                .accessibilityValue(hrTile?.value.accessibilityValue ?? "Unavailable")
                .padding(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))

                // Power or Cadence Box
                let activePowerOrCadence = (powerTile?.value.availability == .available) ? powerTile : cadenceTile
                VStack(alignment: .leading, spacing: 1) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.yellow)
                        Text(activePowerOrCadence?.title ?? "POWER")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(activePowerOrCadence?.value.primaryText ?? "--")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.yellow)
                        Text(activePowerOrCadence?.value.unitText ?? "W")
                            .font(.system(size: 7))
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(activePowerOrCadence?.value.accessibilityLabel ?? "Power")
                .accessibilityValue(activePowerOrCadence?.value.accessibilityValue ?? "Unavailable")
                .padding(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
            }

            // Row 3: Distance & Time & Altitude
            let distTile = state.tile(for: .distance)
            let timeTile = state.tile(for: .movingTime) ?? state.tile(for: .elapsedTime)
            let altTile = state.tile(for: .altitude)

            HStack(spacing: 4) {
                // Distance
                VStack(alignment: .leading, spacing: 1) {
                    Text(distTile?.title ?? "DISTANCE")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(distTile?.value.primaryText ?? "--")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text(distTile?.value.unitText ?? "km")
                        .font(.system(size: 7))
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(distTile?.value.accessibilityLabel ?? "Distance")
                .accessibilityValue(distTile?.value.accessibilityValue ?? "Unavailable")
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))

                // Moving Time
                VStack(alignment: .leading, spacing: 1) {
                    Text(timeTile?.title ?? "TIME")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(timeTile?.value.primaryText ?? "00:00")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text("MOVING")
                        .font(.system(size: 7))
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(timeTile?.value.accessibilityLabel ?? "Time")
                .accessibilityValue(timeTile?.value.accessibilityValue ?? "0 minutes")
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))

                // Altitude
                VStack(alignment: .leading, spacing: 1) {
                    Text(altTile?.title ?? "ALTITUDE")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(altTile?.value.primaryText ?? "--")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.cyan)
                    Text(altTile?.value.unitText ?? "m")
                        .font(.system(size: 7))
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(altTile?.value.accessibilityLabel ?? "Altitude")
                .accessibilityValue(altTile?.value.accessibilityValue ?? "Unavailable")
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 4)
    }
}
