import SwiftUI

/// Chronological Turn Cue Sheet / Waypoint list with live distance countdowns.
public struct CueSheetListView: View {
    @Environment(CyclingRideEngine.self) private var engine

    public var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Image(systemName: "signpost.right.and.left.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
                Text("CUE SHEET & TURNS")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(upcomingCues.count) upcoming")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.cyan)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))

            if upcomingCues.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "flag.checkered")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("No upcoming turns")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(upcomingCues) { cue in
                    HStack(spacing: 8) {
                        Image(systemName: cue.type.iconName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(iconColor(cue.type))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(cue.instruction)
                                .font(.system(size: 11, weight: .bold))
                                .lineLimit(2)
                                .foregroundStyle(.white)

                            let dist = max(0, cue.distanceFromStart - engine.totalDistanceMeters)
                            Text(formattedDistance(dist))
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
                    .listRowBackground(Color.black.opacity(0.6))
                }
                .listStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
    }

    private var upcomingCues: [RouteCue] {
        guard let route = engine.activeRoute else { return [] }
        return route.cues.filter { $0.distanceFromStart >= (engine.totalDistanceMeters - 20) }
    }

    private func iconColor(_ type: CueType) -> Color {
        switch type {
        case .summit: return .orange
        case .water: return .cyan
        case .food: return .yellow
        case .hazard: return .red
        case .start: return .green
        case .end: return .purple
        default: return .white
        }
    }

    private func formattedDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "in %.1f km", meters / 1000.0)
        }
        return "in \(Int(meters)) m"
    }
}
