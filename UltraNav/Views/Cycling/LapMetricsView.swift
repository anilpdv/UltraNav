import SwiftUI

/// Lap splits summary and manual lap trigger screen.
public struct LapMetricsView: View {
    @Environment(RideViewModel.self) private var rideViewModel
    @Environment(MetricsViewModel.self) private var metricsViewModel

    public init() {}

    public var body: some View {
        let rideState = rideViewModel.state
        let metricsState = metricsViewModel.state

        VStack(spacing: 3) {
            // Current Lap / Ride Live HUD
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("ACTIVE RIDE")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                    Text(rideState.movingTime)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }

                Spacer()

                let distTile = metricsState.tile(for: .distance)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("DISTANCE")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("\(distTile?.value.primaryText ?? "0.0") \(distTile?.value.unitText ?? "km")")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))

            VStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Ride in progress")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Moving: \(rideState.movingTime) | Elapsed: \(rideState.elapsedTime)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Primary Control Action Button
            if let action = rideState.controls.primaryAction {
                Button {
                    rideViewModel.handle(.primaryControlSelected)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: rideState.phase == .paused ? "play.fill" : "pause.fill")
                        Text(rideState.phase == .paused ? "RESUME RIDE" : "PAUSE RIDE")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(rideState.phase == .paused ? .green : .yellow)
                .padding(.horizontal, 4)
                .disabled(!rideState.controls.primaryEnabled)
            }
        }
        .padding(.horizontal, 4)
    }
}
