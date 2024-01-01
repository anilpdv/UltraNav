import SwiftUI

/// Garmin ClimbPro & Elevation Profile screen with color-coded gradient slope bands.
public struct ClimbProView: View {
    @Environment(CyclingRideEngine.self) private var engine

    public var body: some View {
        VStack(spacing: 3) {
            // Header: Active Climb or Elevation Summary
            if let climb = engine.currentClimb {
                HStack(spacing: 6) {
                    Text("CLIMB \(climb.climbIndex)/\(climb.totalClimbs)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text(climb.category.rawValue)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color(hex: climb.category.badgeColorHex), in: Capsule())
                        .foregroundStyle(.black)

                    Spacer()

                    Text("\(Int(engine.distanceRemainingInClimb))m to top")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.yellow)
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
                    Text("+\(Int(engine.elevationGainedMeters))m gained")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
            }

            // Elevation Profile Chart
            ElevationCanvas(
                points: engine.activeRoute?.points ?? [],
                currentDistance: engine.totalDistanceMeters,
                currentElevation: engine.currentElevationMeters
            )
            .frame(maxHeight: .infinity)
            .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))

            // Footer: Live Grade %, Current Altitude & VAM
            HStack(spacing: 4) {
                // Live Grade
                VStack(alignment: .leading, spacing: 0) {
                    Text("GRADE")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%+.1f%%", engine.currentGradePercent))
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(gradeColor(engine.currentGradePercent))
                }
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 6))

                // Altitude
                VStack(alignment: .leading, spacing: 0) {
                    Text("ALTITUDE")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text("\(Int(engine.currentElevationMeters))m")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 6))

                // VAM (Vertical Ascent Meters / Hour)
                VStack(alignment: .leading, spacing: 0) {
                    Text("VAM")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text("\(Int(engine.vamMetersPerHour))")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.cyan)
                    Text("m/h")
                        .font(.system(size: 6))
                        .foregroundStyle(.secondary)
                }
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.horizontal, 4)
    }

    private func gradeColor(_ grade: Double) -> Color {
        if grade >= 10 { return .red }
        if grade >= 7 { return .orange }
        if grade >= 4 { return .yellow }
        if grade > 0 { return .green }
        return .cyan
    }
}

/// Standalone elevation profile graph renderer
private struct ElevationCanvas: View {
    let points: [TrackPoint]
    let currentDistance: Double
    let currentElevation: Double

    var body: some View {
        Canvas { context, size in
            guard points.count > 1 else {
                // Placeholder profile if no route points
                drawEmptyProfile(context: context, size: size)
                return
            }

            let maxDist = points.last?.distanceFromStart ?? 1.0
            var minEle: Double = .infinity
            var maxEle: Double = -.infinity

            for pt in points {
                if let ele = pt.elevation {
                    if ele < minEle { minEle = ele }
                    if ele > maxEle { maxEle = ele }
                }
            }
            if minEle == .infinity { minEle = 0 }
            if maxEle == -.infinity { maxEle = 100 }
            let eleRange = max(20.0, maxEle - minEle)

            // Step 1: Draw Gradient Filled Segments
            let step = max(1, points.count / 80)
            for i in stride(from: 0, to: points.count - step, by: step) {
                let p1 = points[i]
                let p2 = points[i + step]
                let e1 = p1.elevation ?? minEle
                let e2 = p2.elevation ?? minEle

                let x1 = (p1.distanceFromStart / maxDist) * size.width
                let x2 = (p2.distanceFromStart / maxDist) * size.width
                let y1 = size.height - CGFloat((e1 - minEle) / eleRange) * (size.height - 12) - 4
                let y2 = size.height - CGFloat((e2 - minEle) / eleRange) * (size.height - 12) - 4

                let dDist = p2.distanceFromStart - p1.distanceFromStart
                let grade = dDist > 0 ? ((e2 - e1) / dDist) * 100.0 : 0
                let segColor = gradientSlopeColor(grade)

                var fillPath = Path()
                fillPath.move(to: CGPoint(x: x1, y: size.height))
                fillPath.addLine(to: CGPoint(x: x1, y: y1))
                fillPath.addLine(to: CGPoint(x: x2, y: y2))
                fillPath.addLine(to: CGPoint(x: x2, y: size.height))
                fillPath.closeSubpath()

                let isCompleted = p2.distanceFromStart <= currentDistance
                context.fill(fillPath, with: .color(isCompleted ? segColor.opacity(0.85) : segColor.opacity(0.35)))
            }

            // Step 2: Draw Continuous Top Outline
            var linePath = Path()
            for (idx, pt) in points.enumerated() {
                let ele = pt.elevation ?? minEle
                let x = (pt.distanceFromStart / maxDist) * size.width
                let y = size.height - CGFloat((ele - minEle) / eleRange) * (size.height - 12) - 4
                if idx == 0 {
                    linePath.move(to: CGPoint(x: x, y: y))
                } else {
                    linePath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(linePath, with: .color(.white), lineWidth: 1.5)

            // Step 3: Draw Rider Current Position Pin
            let riderProgress = min(1.0, currentDistance / maxDist)
            let riderX = riderProgress * size.width
            let riderY = size.height - CGFloat((currentElevation - minEle) / eleRange) * (size.height - 12) - 4

            let dot = CGRect(x: riderX - 4, y: riderY - 4, width: 8, height: 8)
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

    private func gradientSlopeColor(_ grade: Double) -> Color {
        if grade >= 12 { return Color(red: 0.7, green: 0.1, blue: 0.8) } // Purple HC
        if grade >= 9 { return .red }
        if grade >= 6 { return .orange }
        if grade >= 3 { return .yellow }
        if grade >= 0 { return .green }
        return .cyan
    }
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
