import Foundation

/// Calculation engine for elevation gain, grade %, VAM, and active climb progress.
@MainActor
final class ClimbEngine {
    private(set) var currentElevationMeters: Double?
    private(set) var elevationGainedMeters: Double = 0
    private(set) var currentGradePercent: Double = 0
    private(set) var vamMetersPerHour: Double = 0

    private(set) var currentClimb: ClimbSegment?
    private(set) var distanceRemainingInClimb: Double = 0

    private var recentElevations: [(time: Date, alt: Double, dist: Double)] = []
    private var lastAltitude: Double?

    init() {}

    func reset() {
        self.currentElevationMeters = nil
        self.elevationGainedMeters = 0
        self.currentGradePercent = 0
        self.vamMetersPerHour = 0
        self.currentClimb = nil
        self.distanceRemainingInClimb = 0
        self.recentElevations = []
        self.lastAltitude = nil
    }

    func update(location: LocationSample, totalDistance: Double, route: GPXRoute?) {
        guard let altitude = location.altitudeMeters else { return }
        self.currentElevationMeters = altitude

        if let last = lastAltitude {
            let dAlt = altitude - last
            if dAlt > 0.6 {
                elevationGainedMeters += dAlt
            }
        }
        self.lastAltitude = altitude

        // Update Grade % and VAM with rolling window
        let now = location.timestamp
        recentElevations.append((time: now, alt: altitude, dist: totalDistance))
        recentElevations.removeAll { now.timeIntervalSince($0.time) > 15 }

        if let first = recentElevations.first, recentElevations.count >= 3 {
            let deltaDist = totalDistance - first.dist
            let deltaAlt = altitude - first.alt
            let deltaTime = now.timeIntervalSince(first.time)

            if deltaDist > 15 {
                let rawGrade = (deltaAlt / deltaDist) * 100.0
                self.currentGradePercent = (self.currentGradePercent * 0.7) + (rawGrade * 0.3)
            }

            if deltaTime > 5 && deltaAlt > 0 {
                self.vamMetersPerHour = (deltaAlt / deltaTime) * 3600.0
            }
        }

        // Check active climb in route
        if let route {
            if let climb = route.climbs.first(where: { totalDistance >= $0.startDistance && totalDistance <= $0.endDistance }) {
                self.currentClimb = climb
                self.distanceRemainingInClimb = max(0, climb.endDistance - totalDistance)
            } else {
                self.currentClimb = nil
                self.distanceRemainingInClimb = 0
            }
        }
    }

    var snapshot: ClimbSnapshot {
        ClimbSnapshot(
            currentClimb: currentClimb,
            distanceRemainingInClimb: distanceRemainingInClimb,
            currentElevationMeters: currentElevationMeters,
            elevationGainedMeters: elevationGainedMeters,
            currentGradePercent: currentGradePercent,
            vamMetersPerHour: vamMetersPerHour
        )
    }
}
