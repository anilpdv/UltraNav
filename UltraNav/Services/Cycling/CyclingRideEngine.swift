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
final class CyclingRideEngine: NSObject, CLLocationManagerDelegate {
    static let shared = CyclingRideEngine()

    let rideEngine: RideEngine

    // MARK: - Ride Lifecycle
    var isRiding: Bool {
        get { rideEngine.state == .active || rideEngine.state == .paused }
        set { /* forwarded via start/finish */ }
    }
    var isPaused: Bool {
        get { rideEngine.state == .paused }
        set { /* forwarded via pause/resume */ }
    }
    var activeRoute: GPXRoute? {
        get { rideEngine.navigationEngine.activeRoute }
        set {
            if let newValue {
                rideEngine.navigationEngine.load(route: newValue)
            } else {
                rideEngine.navigationEngine.reset()
            }
        }
    }

    // MARK: - Live Cycling Metrics (Derived from Snapshots)
    var currentSpeedKmh: Double {
        (rideEngine.rideSnapshot.metrics.currentSpeedMetersPerSecond ?? 0) * 3.6
    }
    var averageSpeedKmh: Double {
        rideEngine.rideSnapshot.movingTimeSeconds > 0
            ? (rideEngine.rideSnapshot.metrics.distanceMeters / rideEngine.rideSnapshot.movingTimeSeconds) * 3.6
            : 0
    }
    var maxSpeedKmh: Double {
        rideEngine.metricsEngine.maxSpeedMetersPerSecond * 3.6
    }
    var totalDistanceMeters: CLLocationDistance {
        rideEngine.rideSnapshot.metrics.distanceMeters
    }
    var elapsedTime: TimeInterval {
        rideEngine.rideSnapshot.elapsedTimeSeconds
    }
    var movingTime: TimeInterval {
        rideEngine.rideSnapshot.movingTimeSeconds
    }

    // Elevation & Grade
    var currentElevationMeters: Double {
        rideEngine.climbEngine.currentElevationMeters ?? 0
    }
    var elevationGainedMeters: Double {
        rideEngine.climbEngine.elevationGainedMeters
    }
    var currentGradePercent: Double {
        rideEngine.climbEngine.currentGradePercent
    }
    var vamMetersPerHour: Double {
        rideEngine.climbEngine.vamMetersPerHour
    }

    // Sensor Metrics (BLE / HealthKit)
    var heartRate: Int {
        rideEngine.rideSnapshot.metrics.heartRateBeatsPerMinute ?? 0
    }
    var cadenceRPM: Int {
        Int(rideEngine.rideSnapshot.metrics.cadenceRevolutionsPerMinute ?? 0)
    }
    var powerWatts: Int {
        rideEngine.rideSnapshot.metrics.powerWatts ?? 0
    }
    var activeCalories: Int {
        rideEngine.metricsEngine.activeCalories
    }

    // MARK: - Navigation & Turn Engine
    var currentLocation: CLLocation? {
        rideEngine.lastSample.map {
            CLLocation(
                coordinate: $0.coordinate.clCoordinate,
                altitude: $0.altitudeMeters ?? 0,
                horizontalAccuracy: $0.horizontalAccuracyMeters,
                verticalAccuracy: $0.verticalAccuracyMeters ?? 0,
                course: $0.courseDegrees ?? 0,
                speed: $0.speedMetersPerSecond ?? 0,
                timestamp: $0.timestamp
            )
        }
    }
    var currentHeading: Double {
        rideEngine.currentHeading
    }
    var breadcrumbHistory: [CLLocationCoordinate2D] {
        rideEngine.navigationEngine.breadcrumbTrail.map(\.clCoordinate)
    }
    var isOffCourse: Bool {
        rideEngine.navigationSnapshot.state == .offRoute
    }
    var crossTrackErrorMeters: CLLocationDistance {
        rideEngine.navigationSnapshot.crossTrackDistanceMeters ?? 0
    }
    var nextCue: RouteCue? {
        rideEngine.navigationEngine.nextCue
    }
    var distanceToNextCue: CLLocationDistance {
        rideEngine.navigationSnapshot.distanceToNextCueMeters ?? 0
    }
    var currentClimb: ClimbSegment? {
        rideEngine.climbEngine.currentClimb
    }
    var distanceRemainingInClimb: CLLocationDistance {
        rideEngine.climbEngine.distanceRemainingInClimb
    }

    // MARK: - Lap Engine
    var laps: [LapRecord] {
        rideEngine.metricsEngine.laps
    }
    var currentLapDuration: TimeInterval {
        rideEngine.metricsEngine.currentLapDuration
    }
    var currentLapDistance: CLLocationDistance {
        rideEngine.metricsEngine.currentLapDistance
    }

    // Configuration
    var maxHeartRate: Int = 185
    var isAutoPauseEnabled: Bool {
        get { rideEngine.metricsEngine.isAutoPauseEnabled }
        set { rideEngine.metricsEngine.isAutoPauseEnabled = newValue }
    }
    var autoLapDistanceMeters: CLLocationDistance {
        get { rideEngine.metricsEngine.autoLapDistanceMeters }
        set { rideEngine.metricsEngine.autoLapDistanceMeters = newValue }
    }

    override init() {
        let loc = LocationService()
        let work = HealthKitService()
        let sens = BluetoothService()
        let clk = SystemClock()

        self.rideEngine = RideEngine(
            locationService: loc,
            workoutService: work,
            sensorService: sens,
            clock: clk
        )
        super.init()
    }

    init(rideEngine: RideEngine) {
        self.rideEngine = rideEngine
        super.init()
    }

    func heartRateZone(for hr: Int) -> HeartRateZone {
        guard hr > 0 else { return .zone1 }
        let pct = Double(hr) / Double(maxHeartRate)
        if pct < 0.60 { return .zone1 }
        if pct < 0.70 { return .zone2 }
        if pct < 0.80 { return .zone3 }
        if pct < 0.90 { return .zone4 }
        return .zone5
    }

    var heartRateZone: HeartRateZone {
        heartRateZone(for: heartRate)
    }

    var speedComparison: Int {
        if currentSpeedKmh > averageSpeedKmh + 0.5 { return 1 }
        if currentSpeedKmh < averageSpeedKmh - 0.5 { return -1 }
        return 0
    }

    // MARK: - Ride Controls
    func startRide(route: GPXRoute? = nil) {
        Task {
            try? await rideEngine.startRide(route: route)
        }
    }

    func pauseRide() {
        rideEngine.pauseRide()
    }

    func resumeRide() {
        rideEngine.resumeRide()
    }

    func triggerManualLap() {
        rideEngine.triggerManualLap()
    }

    func finishRide() {
        Task {
            try? await rideEngine.finishRide()
        }
    }
}
