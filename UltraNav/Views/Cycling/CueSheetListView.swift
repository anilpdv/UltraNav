import SwiftUI

/// Chronological Turn Cue Sheet / Waypoint list with live distance countdowns.
public struct CueSheetListView: View {
    @Environment(NavigationViewModel.self) private var navViewModel

    public init() {}

    public var body: some View {
        let state = navViewModel.state

        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Image(systemName: "signpost.right.and.left.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
                Text("CUE SHEET & TURNS")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                if let dist = state.distanceRemaining {
                    Text("\(dist.primaryText) \(dist.unitText) left")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.cyan)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))

            if let cue = state.nextCue {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: cue.maneuver.iconName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.green)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(cue.instruction)
                                .font(.system(size: 13, weight: .bold))
                                .lineLimit(3)
                                .foregroundStyle(.white)

                            if let dist = cue.distance {
                                Text("in \(dist.primaryText) \(dist.unitText)")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.yellow)
                            }
                        }

                        Spacer()
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))

                    Spacer()
                }
                .padding(.top, 4)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "flag.checkered")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("No active turn cues")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 4)
    }
}
