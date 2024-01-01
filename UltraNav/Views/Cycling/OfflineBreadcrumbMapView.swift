import SwiftUI
import CoreLocation

/// 100% Offline Vector & Breadcrumb Map renderer for Apple Watch Ultra.
/// Operates without any internet connection, cellular signal, or map tiles.
public struct OfflineBreadcrumbMapView: View {
    @Environment(CyclingRideEngine.self) private var engine
    @State private var zoomScale: Double = 1.0
    @State private var isTrackUp: Bool = true

    public var body: some View {
        ZStack {
            // Standalone Vector Canvas
            Canvas { context, size in
                drawOfflineVectorMap(context: context, size: size)
            }
            .background(Color.black)
            .focusable()
            .digitalCrownRotation($zoomScale, from: 0.4, through: 4.0, by: 0.1, sensitivity: .medium)

            // Overlays: Turn Pill, Off-Course Banner, Controls
            VStack(spacing: 3) {
                // Off-Course Alert Banner
                if engine.isOffCourse {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text("OFF COURSE (+\(Int(engine.crossTrackErrorMeters))m)")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red, in: Capsule())
                    .foregroundStyle(.white)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Dynamic Turn Instruction Banner
                if let cue = engine.nextCue {
                    HStack(spacing: 6) {
                        Image(systemName: cue.type.iconName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(Int(engine.distanceToNextCue))m")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Text(cue.instruction)
                                .font(.system(size: 8, weight: .medium))
                                .lineLimit(1)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1))
                }

                Spacer()

                // Bottom Map Control Buttons
                HStack(spacing: 8) {
                    Button {
                        isTrackUp.toggle()
                    } label: {
                        Image(systemName: isTrackUp ? "location.north.line.fill" : "safari.fill")
                            .font(.system(size: 10, weight: .bold))
                            .padding(6)
                            .background(Color.black.opacity(0.7), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Zoom Indicator / Reset
                    Button {
                        zoomScale = 1.0
                    } label: {
                        Text(String(format: "%.1fx", zoomScale))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 2)
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
        }
    }

    private func drawOfflineVectorMap(context: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        // Center on User coordinate (or route start if user location unavailable)
        let userCoord = engine.currentLocation?.coordinate ??
            engine.activeRoute?.points.first?.coordinate ??
            CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)

        let metersPerPoint = 4.0 / zoomScale
        let heading = isTrackUp ? engine.currentHeading : 0

        // 1. Draw Grid Lines (Garmin background scale)
        var gridPath = Path()
        let step: CGFloat = 30 * CGFloat(zoomScale)
        if step > 10 {
            for x in stride(from: 0, to: size.width, by: step) {
                gridPath.move(to: CGPoint(x: x, y: 0))
                gridPath.addLine(to: CGPoint(x: x, y: size.height))
            }
            for y in stride(from: 0, to: size.height, by: step) {
                gridPath.move(to: CGPoint(x: 0, y: y))
                gridPath.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(gridPath, with: .color(Color.gray.opacity(0.12)), lineWidth: 0.5)
        }

        // 2. Draw Course Polyline (if active route loaded)
        if let route = engine.activeRoute, route.points.count > 1 {
            var coursePath = Path()
            for (index, pt) in route.points.enumerated() {
                let screenPt = projectCoordinate(
                    pt.coordinate,
                    relativeTo: userCoord,
                    center: center,
                    metersPerPoint: metersPerPoint,
                    heading: heading
                )
                if index == 0 {
                    coursePath.move(to: screenPt)
                } else {
                    coursePath.addLine(to: screenPt)
                }
            }

            // Outer Black Casing for high sunlight visibility
            context.stroke(coursePath, with: .color(.black), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
            // Inner Neon Cyan Course Line (Wahoo ELEMNT Chevron Style)
            context.stroke(coursePath, with: .color(Color(red: 0.0, green: 0.88, blue: 1.0)), style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round))

            // Draw Waypoints / Cues on Course
            for cue in route.cues {
                let cuePt = projectCoordinate(
                    cue.coordinate,
                    relativeTo: userCoord,
                    center: center,
                    metersPerPoint: metersPerPoint,
                    heading: heading
                )
                let rect = CGRect(x: cuePt.x - 4, y: cuePt.y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: rect), with: .color(.yellow))
                context.stroke(Path(ellipseIn: rect), with: .color(.black), lineWidth: 1.5)
            }
        }

        // 3. Draw Breadcrumb History (Rider's actual ridden trail)
        if engine.breadcrumbHistory.count > 1 {
            var crumbPath = Path()
            for (index, coord) in engine.breadcrumbHistory.enumerated() {
                let screenPt = projectCoordinate(
                    coord,
                    relativeTo: userCoord,
                    center: center,
                    metersPerPoint: metersPerPoint,
                    heading: heading
                )
                if index == 0 {
                    crumbPath.move(to: screenPt)
                } else {
                    crumbPath.addLine(to: screenPt)
                }
            }
            context.stroke(crumbPath, with: .color(Color.white.opacity(0.85)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: [4, 3]))
        }

        // 4. Draw Current User Position & Heading Cone (Garmin / Wahoo style arrow)
        var userArrow = Path()
        userArrow.move(to: CGPoint(x: center.x, y: center.y - 8))
        userArrow.addLine(to: CGPoint(x: center.x + 6, y: center.y + 7))
        userArrow.addLine(to: CGPoint(x: center.x, y: center.y + 3))
        userArrow.addLine(to: CGPoint(x: center.x - 6, y: center.y + 7))
        userArrow.closeSubpath()

        // Rotate arrow if North-up mode is active
        var arrowContext = context
        if !isTrackUp && engine.currentHeading != 0 {
            arrowContext.translateBy(x: center.x, y: center.y)
            arrowContext.rotate(by: Angle.degrees(engine.currentHeading))
            arrowContext.translateBy(x: -center.x, y: -center.y)
        }

        // Shadow/Casing
        arrowContext.fill(userArrow, with: .color(Color(red: 0.15, green: 1.0, blue: 0.3))) // Neon Green
        arrowContext.stroke(userArrow, with: .color(.black), lineWidth: 2)
    }

    private func projectCoordinate(
        _ coord: CLLocationCoordinate2D,
        relativeTo origin: CLLocationCoordinate2D,
        center: CGPoint,
        metersPerPoint: Double,
        heading: Double
    ) -> CGPoint {
        // Equirectangular projection relative to origin
        let latDistance = (coord.latitude - origin.latitude) * 111_139.0
        let lonDistance = (coord.longitude - origin.longitude) * 111_139.0 * cos(origin.latitude * .pi / 180.0)

        // Screen coordinates: North is -Y, East is +X
        var screenX = lonDistance / metersPerPoint
        var screenY = -latDistance / metersPerPoint

        // Rotate if track-up mode is active (rotate by -heading)
        if heading != 0 {
            let rad = -heading * .pi / 180.0
            let rotatedX = screenX * cos(rad) - screenY * sin(rad)
            let rotatedY = screenX * sin(rad) + screenY * cos(rad)
            screenX = rotatedX
            screenY = rotatedY
        }

        return CGPoint(x: center.x + CGFloat(screenX), y: center.y + CGFloat(screenY))
    }
}
