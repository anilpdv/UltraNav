import SwiftUI

/// Wahoo & Garmin style high-contrast sunlight-readable cycling computer metrics matrix.
public struct MetricsGridView: View {
    @Environment(CyclingRideEngine.self) private var engine

    public var body: some View {
        VStack(spacing: 4) {
            // Row 1: Primary Speed (Big Numbers)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("SPEED")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", engine.currentSpeedKmh))
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)

                        // Speed Pace Arrow
                        if engine.speedComparison > 0 {
                            Image(systemName: "triangle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.green)
                        } else if engine.speedComparison < 0 {
                            Image(systemName: "triangle.fill")
                                .font(.system(size: 10))
                                .rotationEffect(.degrees(180))
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 0) {
                    Text("AVG")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", engine.averageSpeedKmh))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.cyan)
                    Text("km/h")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))

            // Row 2: Heart Rate + Zone & Power / Cadence
            HStack(spacing: 4) {
                // Heart Rate Box
                VStack(alignment: .leading, spacing: 1) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(engine.heartRateZone.color)
                        Text("HEART RATE")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(engine.heartRate > 0 ? "\(engine.heartRate)" : "--")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(engine.heartRateZone.color)
                        Text("bpm")
                            .font(.system(size: 7))
                            .foregroundStyle(.secondary)
                    }
                    // HR Zone Bar
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.3)).frame(height: 3)
                        Capsule()
                            .fill(engine.heartRateZone.color)
                            .frame(width: max(4, CGFloat(engine.heartRateZone.rawValue) * 12), height: 3)
                    }
                }
                .padding(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))

                // Power or Cadence Box
                VStack(alignment: .leading, spacing: 1) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.yellow)
                        Text("POWER")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(engine.powerWatts > 0 ? "\(engine.powerWatts)" : (engine.cadenceRPM > 0 ? "\(engine.cadenceRPM)" : "--"))
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.yellow)
                        Text(engine.powerWatts > 0 ? "W" : "rpm")
                            .font(.system(size: 7))
                            .foregroundStyle(.secondary)
                    }
                    Text(engine.cadenceRPM > 0 ? "\(engine.cadenceRPM) rpm" : "CADENCE")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
            }

            // Row 3: Distance & Time & Grade %
            HStack(spacing: 4) {
                // Distance
                VStack(alignment: .leading, spacing: 1) {
                    Text("DISTANCE")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", engine.totalDistanceMeters / 1000.0))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text("km")
                        .font(.system(size: 7))
                        .foregroundStyle(.secondary)
                }
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))

                // Moving Time
                VStack(alignment: .leading, spacing: 1) {
                    Text("TIME")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(formattedTime(engine.movingTime))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text("MOVING")
                        .font(.system(size: 7))
                        .foregroundStyle(.secondary)
                }
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))

                // Grade %
                VStack(alignment: .leading, spacing: 1) {
                    Text("GRADE")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%+.1f%%", engine.currentGradePercent))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(gradeColor(engine.currentGradePercent))
                    Text("+\(Int(engine.elevationGainedMeters))m")
                        .font(.system(size: 7))
                        .foregroundStyle(.secondary)
                }
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 4)
    }

    private func formattedTime(_ interval: TimeInterval) -> String {
        let hrs = Int(interval) / 3600
        let mins = (Int(interval) % 3600) / 60
        let secs = Int(interval) % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
    }

    private func gradeColor(_ grade: Double) -> Color {
        if grade >= 10 { return .red }
        if grade >= 7 { return .orange }
        if grade >= 4 { return .yellow }
        if grade > 0 { return .green }
        return .cyan
    }
}
