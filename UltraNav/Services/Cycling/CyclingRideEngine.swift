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
    let navigationEngine: NavigationEngine
    let metricsEngine: MetricsEngine
    let climbEngine: ClimbEngine

    // MARK: - Ride Lifecycle
    var isRiding: Bool {
        get { rideEngine.currentSnapshot.state.hasActiveRideSession }
        set { /* forwarded via start/finish */ }
    }
    var isPaused: Bool {
        get { rideEngine.currentSnapshot.state == .paused }
        set { /* forwarded via pause/resume */ }
    }
    var activeRoute: GPXRoute? {
        get { navigationEngine.activeRoute }
        set {
            if let newValue {
                navigationEngine.load(route: newValue)
            } else {
                navigationEngine.reset()
            }
        }
    }

    // MARK: - Live Cycling Metrics (Derived from Snapshots)
    var currentSpeedKmh: Double {
        (rideEngine.currentSnapshot.metrics.currentSpeedMetersPerSecond ?? 0) * 3.6
    }
    var averageSpeedKmh: Double {
        rideEngine.currentSnapshot.movingTimeSeconds > 0
            ? (rideEngine.currentSnapshot.metrics.distanceMeters / rideEngine.currentSnapshot.movingTimeSeconds) * 3.6
            : 0
    }
    var maxSpeedKmh: Double {
        metricsEngine.maxSpeedMetersPerSecond * 3.6
    }
    var totalDistanceMeters: CLLocationDistance {
        rideEngine.currentSnapshot.metrics.distanceMeters
    }
    var elapsedTime: TimeInterval {
        rideEngine.currentSnapshot.elapsedTimeSeconds
    }
    var movingTime: TimeInterval {
        rideEngine.currentSnapshot.movingTimeSeconds
    }

    // Elevation & Grade
    var currentElevationMeters: Double {
        rideEngine.currentSnapshot.metrics.altitudeMeters ?? climbEngine.currentElevationMeters ?? 0
    }
    var elevationGainedMeters: Double {
        climbEngine.elevationGainedMeters
    }
    var currentGradePercent: Double {
        climbEngine.currentGradePercent
    }
    var vamMetersPerHour: Double {
        climbEngine.vamMetersPerHour
    }

    // Sensor Metrics (BLE / HealthKit)
    var heartRate: Int {
        rideEngine.currentSnapshot.metrics.heartRateBeatsPerMinute ?? 0
    }
    var cadenceRPM: Int {
        Int(rideEngine.currentSnapshot.metrics.cadenceRevolutionsPerMinute ?? 0)
    }
    var powerWatts: Int {
        rideEngine.currentSnapshot.metrics.powerWatts ?? 0
    }
    var activeCalories: Int {
        metricsEngine.activeCalories
    }

    // MARK: - Navigation & Turn Engine
    var currentLocation: CLLocation? {
        nil
    }
    var currentHeading: Double {
        0.0
    }
    var breadcrumbHistory: [CLLocationCoordinate2D] {
        navigationEngine.breadcrumbTrail.map(\.clCoordinate)
    }
    var isOffCourse: Bool {
        navigationEngine.snapshot.state == .offRoute
    }
    var crossTrackErrorMeters: CLLocationDistance {
        navigationEngine.snapshot.crossTrackDistanceMeters ?? 0
    }
    var nextCue: RouteCue? {
        navigationEngine.nextCue
    }
    var distanceToNextCue: CLLocationDistance {
        navigationEngine.snapshot.distanceToNextCueMeters ?? 0
    }
    var currentClimb: ClimbSegment? {
        climbEngine.currentClimb
    }
    var distanceRemainingInClimb: CLLocationDistance {
        climbEngine.distanceRemainingInClimb
    }

    // MARK: - Lap Engine
    var laps: [LapRecord] {
        metricsEngine.laps
    }
    var currentLapDuration: TimeInterval {
        metricsEngine.currentLapDuration
    }
    var currentLapDistance: CLLocationDistance {
        metricsEngine.currentLapDistance
    }

    // Configuration
    var maxHeartRate: Int = 185
    var isAutoPauseEnabled: Bool {
        get { metricsEngine.isAutoPauseEnabled }
        set { metricsEngine.isAutoPauseEnabled = newValue }
    }
    var autoLapDistanceMeters: CLLocationDistance {
        get { metricsEngine.autoLapDistanceMeters }
        set { metricsEngine.autoLapDistanceMeters = newValue }
    }

    override init() {
        let loc = LocationService()
        let work = HealthKitService()
        let sens = BluetoothService()
        let clk = SystemClock()

        self.rideEngine = RideEngine(
            location: loc,
            workout: work,
            sensors: sens,
            clock: clk
        )
        self.navigationEngine = NavigationEngine()
        self.metricsEngine = MetricsEngine()
        self.climbEngine = ClimbEngine()
        super.init()
    }

    init(
        rideEngine: RideEngine,
        navigationEngine: NavigationEngine = NavigationEngine(),
        metricsEngine: MetricsEngine = MetricsEngine(),
        climbEngine: ClimbEngine = ClimbEngine()
    ) {
        self.rideEngine = rideEngine
        self.navigationEngine = navigationEngine
        self.metricsEngine = metricsEngine
        self.climbEngine = climbEngine
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
        if let route {
            navigationEngine.load(route: route)
        }
        Task {
            if rideEngine.currentSnapshot.state == .idle {
                await rideEngine.send(.prepare)
            }
            await rideEngine.send(.start)
        }
    }

    func pauseRide() {
        Task {
            await rideEngine.send(.pause)
        }
    }

    func resumeRide() {
        Task {
            await rideEngine.send(.resume)
        }
    }

    func triggerManualLap() {
        let _ = metricsEngine.triggerLap(at: Date())
        WKInterfaceDevice.current().play(.directionUp)
    }

    func finishRide() {
        Task {
            await rideEngine.send(.finish)
        }
    }
}
