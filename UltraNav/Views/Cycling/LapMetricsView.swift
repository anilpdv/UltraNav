import SwiftUI

/// Lap splits summary and manual lap trigger screen.
public struct LapMetricsView: View {
    @Environment(CyclingRideEngine.self) private var engine

    public var body: some View {
        VStack(spacing: 3) {
            // Current Lap Live HUD
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("CURRENT LAP #\(engine.laps.count + 1)")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                    Text(formattedTime(engine.currentLapDuration))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    Text("LAP DIST")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f km", engine.currentLapDistance / 1000.0))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))

            // Lap List
            if engine.laps.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("No laps recorded yet")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(engine.laps.reversed()) { lap in
                    HStack {
                        Text("Lap \(lap.lapNumber)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.cyan)

                        Spacer()

                        Text(formattedTime(lap.duration))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .monospacedDigit()

                        Text(String(format: "%.2f km", lap.distance / 1000.0))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()

                        Text(String(format: "%.1f kph", lap.avgSpeedKmh))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                            .monospacedDigit()
                    }
                    .listRowInsets(EdgeInsets(top: 3, leading: 6, bottom: 3, trailing: 6))
                    .listRowBackground(Color.black.opacity(0.6))
                }
                .listStyle(.plain)
            }

            // Lap Action Button (Tap or Apple Watch Action Button)
            Button {
                engine.triggerManualLap()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("LAP SPLIT")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 4)
    }

    private func formattedTime(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
