import SwiftUI
import CoreLocation
import WatchKit
import OSLog

public struct LapRecord: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var lapNumber: Int
    public var duration: TimeInterval
    public var distance: CLLocationDistance
    public var avgSpeedKmh: Double
    public var avgHeartRate: Int
    public var avgPower: Int

    public init(
        id: UUID = UUID(),
        lapNumber: Int,
        duration: TimeInterval,
        distance: CLLocationDistance,
        avgSpeedKmh: Double,
        avgHeartRate: Int = 0,
        avgPower: Int = 0
    ) {
        self.id = id
        self.lapNumber = lapNumber
        self.duration = duration
        self.distance = distance
        self.avgSpeedKmh = avgSpeedKmh
        self.avgHeartRate = avgHeartRate
        self.avgPower = avgPower
    }
}

public enum HeartRateZone: Int, CaseIterable {
    case zone1 = 1 // Recovery (<60% max HR)
    case zone2 = 2 // Endurance (60-70%)
    case zone3 = 3 // Tempo (70-80%)
    case zone4 = 4 // Threshold (80-90%)
    case zone5 = 5 // Anaerobic / VO2 Max (>90%)

    public var title: String {
        switch self {
        case .zone1: return "Z1 Recovery"
        case .zone2: return "Z2 Endurance"
        case .zone3: return "Z3 Tempo"
        case .zone4: return "Z4 Threshold"
        case .zone5: return "Z5 Max"
        }
    }

    public var color: Color {
        switch self {
        case .zone1: return .blue
        case .zone2: return .green
        case .zone3: return .yellow
        case .zone4: return .orange
        case .zone5: return .red
        }
    }
}

@MainActor
@Observable
public final class CyclingRideEngine: NSObject, CLLocationManagerDelegate {
    public static let shared = CyclingRideEngine()

    // MARK: - Ride Lifecycle
    public var isRiding: Bool = false
    public var isPaused: Bool = false
    public var activeRoute: GPXRoute?

    // MARK: - Live Cycling Metrics
    public var currentSpeedKmh: Double = 0
    public var averageSpeedKmh: Double = 0
    public var maxSpeedKmh: Double = 0
    public var totalDistanceMeters: CLLocationDistance = 0
    public var elapsedTime: TimeInterval = 0
    public var movingTime: TimeInterval = 0

    // Elevation & Grade
    public var currentElevationMeters: Double = 0
    public var elevationGainedMeters: Double = 0
    public var currentGradePercent: Double = 0
    public var vamMetersPerHour: Double = 0

    // Sensor Metrics (BLE / HealthKit)
    public var heartRate: Int = 0
    public var cadenceRPM: Int = 0
    public var powerWatts: Int = 0
    public var activeCalories: Int = 0

    // MARK: - Navigation & Turn Engine
    public var currentLocation: CLLocation?
    public var currentHeading: Double = 0
    public var breadcrumbHistory: [CLLocationCoordinate2D] = []
    public var isOffCourse: Bool = false
    public var crossTrackErrorMeters: CLLocationDistance = 0
    public var nextCue: RouteCue?
    public var distanceToNextCue: CLLocationDistance = 0
    public var currentClimb: ClimbSegment?
    public var distanceRemainingInClimb: CLLocationDistance = 0

    // MARK: - Lap Engine
    public var laps: [LapRecord] = []
    public var currentLapDuration: TimeInterval = 0
    public var currentLapDistance: CLLocationDistance = 0
    private var lapStartTime: Date = Date()
    private var lapStartDistance: CLLocationDistance = 0

    // Internal Services
    private let locationManager = CLLocationManager()
    private let sensorManager = BluetoothSensorManager.shared
    private let workoutManager = WorkoutSessionManager.shared

    private var rideTimer: Timer?
    private var rideStartDate: Date?
    private var lastLocation: CLLocation?
    private var lastElevationSampleTime: Date = Date()
    private var recentElevations: [(time: Date, alt: Double, dist: Double)] = []

    // Configuration
    public var maxHeartRate: Int = 185
    public var isAutoPauseEnabled: Bool = true
    public var autoLapDistanceMeters: CLLocationDistance = 5000 // 5km auto lap

    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 2.0
#if !targetEnvironment(simulator)
        locationManager.allowsBackgroundLocationUpdates = true
#endif
    }

    public var heartRateZone: HeartRateZone {
        guard heartRate > 0 else { return .zone1 }
        let pct = Double(heartRate) / Double(maxHeartRate)
        if pct < 0.60 { return .zone1 }
        if pct < 0.70 { return .zone2 }
        if pct < 0.80 { return .zone3 }
        if pct < 0.90 { return .zone4 }
        return .zone5
    }

    public var speedComparison: Int {
        if currentSpeedKmh > averageSpeedKmh + 0.5 { return 1 }
        if currentSpeedKmh < averageSpeedKmh - 0.5 { return -1 }
        return 0
    }

    // MARK: - Ride Controls

    public func startRide(route: GPXRoute? = nil) {
        self.activeRoute = route
        self.isRiding = true
        self.isPaused = false
        self.totalDistanceMeters = 0
        self.elapsedTime = 0
        self.movingTime = 0
        self.elevationGainedMeters = 0
        self.maxSpeedKmh = 0
        self.breadcrumbHistory = []
        self.laps = []
        self.rideStartDate = Date()
        self.lapStartTime = Date()
        self.lapStartDistance = 0
        self.lastLocation = nil
        self.recentElevations = []

        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()

        Task {
            let _ = await workoutManager.requestHealthKitAuthorization()
            await workoutManager.startWorkout()
        }

        startTimer()
        WKInterfaceDevice.current().play(.start)
        AppLogger.lifecycle.info("Started cycling ride engine")
    }

    public func pauseRide() {
        guard isRiding, !isPaused else { return }
        isPaused = true
        workoutManager.pauseWorkout()
        WKInterfaceDevice.current().play(.stop)
    }

    public func resumeRide() {
        guard isRiding, isPaused else { return }
        isPaused = false
        workoutManager.resumeWorkout()
        WKInterfaceDevice.current().play(.start)
    }

    public func triggerManualLap() {
        guard isRiding else { return }
        let lapNum = laps.count + 1
        let duration = currentLapDuration
        let dist = currentLapDistance
        let avgSpd = duration > 0 ? (dist / duration) * 3.6 : 0

        let lap = LapRecord(
            lapNumber: lapNum,
            duration: duration,
            distance: dist,
            avgSpeedKmh: avgSpd,
            avgHeartRate: heartRate,
            avgPower: powerWatts
        )
        laps.append(lap)

        currentLapDuration = 0
        currentLapDistance = 0
        lapStartTime = Date()
        lapStartDistance = totalDistanceMeters
        WKInterfaceDevice.current().play(.directionUp)
        AppLogger.lifecycle.info("Lap \(lapNum, privacy: .public) triggered")
    }

    public func finishRide() {
        isRiding = false
        isPaused = false
        stopTimer()
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()

        Task {
            await workoutManager.stopWorkout()
        }
        WKInterfaceDevice.current().play(.success)
        AppLogger.lifecycle.info("Finished cycling ride")
    }

    // MARK: - Timer & State Update

    private func startTimer() {
        rideTimer?.invalidate()
        rideTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.timerTick()
            }
        }
    }

    private func stopTimer() {
        rideTimer?.invalidate()
        rideTimer = nil
    }

    private func timerTick() {
        guard isRiding, !isPaused else { return }
        elapsedTime += 1

        if let bleHR = sensorManager.liveHeartRate, bleHR > 0 {
            self.heartRate = bleHR
        } else if workoutManager.liveHeartRate > 0 {
            self.heartRate = Int(workoutManager.liveHeartRate.rounded())
        }

        if let blePower = sensorManager.livePower {
            self.powerWatts = blePower
        }

        if let bleCadence = sensorManager.liveCadence {
            self.cadenceRPM = bleCadence
        }

        self.activeCalories = Int(workoutManager.activeCalories)

        if isAutoPauseEnabled && currentSpeedKmh < 1.5 && elapsedTime > 5 {
            // Idle
        } else {
            movingTime += 1
        }

        currentLapDuration += 1

        if movingTime > 0 {
            averageSpeedKmh = (totalDistanceMeters / movingTime) * 3.6
        }

        if currentLapDistance >= autoLapDistanceMeters {
            triggerManualLap()
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0 else { return }
        Task { @MainActor [weak self] in
            self?.processLocationUpdate(location)
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        let headingVal = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor [weak self] in
            self?.currentHeading = headingVal
        }
    }

    private func processLocationUpdate(_ location: CLLocation) {
        self.currentLocation = location
        self.currentElevationMeters = location.altitude

        if let bleSpd = sensorManager.liveSpeedKmh {
            self.currentSpeedKmh = bleSpd
        } else if location.speed >= 0 {
            self.currentSpeedKmh = location.speed * 3.6
        }

        if currentSpeedKmh > maxSpeedKmh {
            maxSpeedKmh = currentSpeedKmh
        }

        if isRiding && !isPaused {
            if let last = lastLocation {
                let dist = location.distance(from: last)
                if dist > 1.5 && dist < 150 {
                    totalDistanceMeters += dist
                    currentLapDistance += dist
                    breadcrumbHistory.append(location.coordinate)

                    let dAlt = location.altitude - last.altitude
                    if dAlt > 0.6 {
                        elevationGainedMeters += dAlt
                    }
                }
            } else {
                breadcrumbHistory.append(location.coordinate)
            }
            lastLocation = location

            updateGradientAndVAM(location: location)

            if let route = activeRoute {
                updateNavigationStatus(location: location, route: route)
            }
        }
    }

    private func updateGradientAndVAM(location: CLLocation) {
        let now = Date()
        recentElevations.append((time: now, alt: location.altitude, dist: totalDistanceMeters))
        recentElevations.removeAll { now.timeIntervalSince($0.time) > 15 }

        if let first = recentElevations.first, recentElevations.count >= 3 {
            let deltaDist = totalDistanceMeters - first.dist
            let deltaAlt = location.altitude - first.alt
            let deltaTime = now.timeIntervalSince(first.time)

            if deltaDist > 15 {
                let rawGrade = (deltaAlt / deltaDist) * 100.0
                self.currentGradePercent = (self.currentGradePercent * 0.7) + (rawGrade * 0.3)
            }

            if deltaTime > 5 && deltaAlt > 0 {
                self.vamMetersPerHour = (deltaAlt / deltaTime) * 3600.0
            }
        }
    }

    private func updateNavigationStatus(location: CLLocation, route: GPXRoute) {
        guard !route.points.isEmpty else { return }

        var minDistance: CLLocationDistance = .infinity
        var closestPointIndex = 0

        for i in 0..<route.points.count {
            let pt = route.points[i]
            let ptLoc = CLLocation(latitude: pt.coordinate.latitude, longitude: pt.coordinate.longitude)
            let d = location.distance(from: ptLoc)
            if d < minDistance {
                minDistance = d
                closestPointIndex = i
            }
        }

        self.crossTrackErrorMeters = minDistance

        if minDistance > 35 && !isOffCourse {
            isOffCourse = true
            WKInterfaceDevice.current().play(.failure)
        } else if minDistance <= 25 && isOffCourse {
            isOffCourse = false
            WKInterfaceDevice.current().play(.directionUp)
        }

        let userRouteDist = route.points[closestPointIndex].distanceFromStart
        if let next = route.cues.first(where: { $0.distanceFromStart >= (userRouteDist - 25) }) {
            self.nextCue = next
            self.distanceToNextCue = max(0, next.distanceFromStart - userRouteDist)
        } else {
            self.nextCue = route.cues.last
            self.distanceToNextCue = max(0, route.totalDistance - userRouteDist)
        }

        if let climb = route.climbs.first(where: { userRouteDist >= $0.startDistance && userRouteDist <= $0.endDistance }) {
            self.currentClimb = climb
            self.distanceRemainingInClimb = max(0, climb.endDistance - userRouteDist)
        } else {
            self.currentClimb = nil
            self.distanceRemainingInClimb = 0
        }
    }
}
