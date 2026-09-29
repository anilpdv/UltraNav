import SwiftUI

/// Garmin ClimbPro & Elevation Profile screen with color-coded gradient slope bands.
public struct ClimbProView: View {
    @Environment(ClimbViewModel.self) private var climbViewModel

    public init() {}

    public var body: some View {
        let state = climbViewModel.state

        VStack(spacing: 3) {
            // Header: Active Climb or Elevation Summary
            if state.phase == .active, let cat = state.categoryText {
                HStack(spacing: 6) {
                    Text("ACTIVE CLIMB")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text(cat)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.yellow, in: Capsule())
                        .foregroundStyle(.black)

                    Spacer()

                    if let remaining = state.distanceRemaining {
                        Text("\(remaining.primaryText) \(remaining.unitText) left")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.yellow)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
            } else {
                HStack {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.cyan)
                    Text("ELEVATION PROFILE")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let elevRemaining = state.elevationRemaining {
                        Text("\(elevRemaining.primaryText) \(elevRemaining.unitText) left")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
            }

            // Elevation Profile Chart
            ElevationCanvas(profile: state.profile)
                .frame(maxHeight: .infinity)
                .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))

            // Footer: Live Grade %, Summit Label
            HStack(spacing: 4) {
                // Live Grade
                VStack(alignment: .leading, spacing: 0) {
                    Text("GRADE")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(state.currentGradient?.primaryText ?? "0.0%")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.cyan)
                }
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 6))

                // Summit
                VStack(alignment: .leading, spacing: 0) {
                    Text("SUMMIT")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(state.profile?.summitLabel ?? "--")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 6))

                // Status Message
                VStack(alignment: .leading, spacing: 0) {
                    Text("STATUS")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(state.message ?? "Ready")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.horizontal, 4)
    }
}

/// Standalone elevation profile graph renderer
private struct ElevationCanvas: View {
    let profile: ClimbProfileViewState?

    var body: some View {
        Canvas { context, size in
            guard let profile = profile, profile.points.count > 1 else {
                drawEmptyProfile(context: context, size: size)
                return
            }

            let points = profile.points

            // Step 1: Draw Gradient Filled Segments
            for i in 0..<(points.count - 1) {
                let p1 = points[i]
                let p2 = points[i + 1]

                let x1 = CGFloat(p1.normalizedDistance) * size.width
                let x2 = CGFloat(p2.normalizedDistance) * size.width
                let y1 = size.height - CGFloat(p1.normalizedElevation) * (size.height - 12) - 4
                let y2 = size.height - CGFloat(p2.normalizedElevation) * (size.height - 12) - 4

                let segColor = gradientSlopeColor(p1.gradientBand)

                var fillPath = Path()
                fillPath.move(to: CGPoint(x: x1, y: size.height))
                fillPath.addLine(to: CGPoint(x: x1, y: y1))
                fillPath.addLine(to: CGPoint(x: x2, y: y2))
                fillPath.addLine(to: CGPoint(x: x2, y: size.height))
                fillPath.closeSubpath()

                let isCompleted = p2.normalizedDistance <= profile.currentProgress
                context.fill(fillPath, with: .color(isCompleted ? segColor.opacity(0.85) : segColor.opacity(0.35)))
            }

            // Step 2: Draw Continuous Top Outline
            var linePath = Path()
            for (idx, pt) in points.enumerated() {
                let x = CGFloat(pt.normalizedDistance) * size.width
                let y = size.height - CGFloat(pt.normalizedElevation) * (size.height - 12) - 4
                if idx == 0 {
                    linePath.move(to: CGPoint(x: x, y: y))
                } else {
                    linePath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(linePath, with: .color(.white), lineWidth: 1.5)

            // Step 3: Draw Rider Current Position Pin
            let riderProgress = min(1.0, max(0.0, profile.currentProgress))
            let riderX = CGFloat(riderProgress) * size.width
            let dot = CGRect(x: riderX - 4, y: size.height / 2 - 4, width: 8, height: 8)
            context.fill(Path(ellipseIn: dot), with: .color(Color(red: 0.15, green: 1.0, blue: 0.3)))
            context.stroke(Path(ellipseIn: dot), with: .color(.black), lineWidth: 1.5)
        }
    }

    private func drawEmptyProfile(context: GraphicsContext, size: CGSize) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height - 15))
        path.addQuadCurve(to: CGPoint(x: size.width, y: size.height - 15), control: CGPoint(x: size.width / 2, y: size.height - 35))
        context.stroke(path, with: .color(.cyan.opacity(0.5)), lineWidth: 2)
    }

    private func gradientSlopeColor(_ band: GradientBandViewState) -> Color {
        switch band {
        case .descent: return .cyan
        case .easy: return .green
        case .moderate: return .yellow
        case .hard: return .orange
        case .severe: return .red
        }
    }
}
