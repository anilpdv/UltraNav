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

    private var navSubscriptionTask: Task<Void, Never>?

    // MARK: - Ride Lifecycle
    var isRiding: Bool {
        get { rideEngine.currentSnapshot.state.hasActiveRideSession }
        set { /* forwarded via start/finish */ }
    }
    var isPaused: Bool {
        get { rideEngine.currentSnapshot.state == .paused }
        set { /* forwarded via pause/resume */ }
    }
    private var _activeRoute: GPXRoute?
    var activeRoute: GPXRoute? {
        get { _activeRoute }
        set {
            _activeRoute = newValue
            if let newValue {
                let domainRoute = newValue.toDomainRoute()
                Task {
                    await navigationEngine.send(.useRoute(domainRoute))
                    await climbEngine.send(.loadRoute(domainRoute))
                }
            } else {
                Task {
                    await navigationEngine.send(.clearRoute)
                    await climbEngine.send(.reset)
                }
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
        (metricsEngine.currentSnapshot.maxSpeedMetersPerSecond ?? 0) * 3.6
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
        rideEngine.currentSnapshot.metrics.altitudeMeters ?? climbEngine.currentSnapshot.currentElevationMeters ?? 0
    }
    var elevationGainedMeters: Double {
        climbEngine.currentSnapshot.totalElevationGainMeters
    }
    var currentGradePercent: Double {
        climbEngine.currentSnapshot.currentGradePercent
    }
    var vamMetersPerHour: Double {
        climbEngine.currentSnapshot.vamMetersPerHour
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
        Int(metricsEngine.currentSnapshot.totalKilocalories ?? 0)
    }

    // MARK: - Navigation & Turn Engine
    var currentLocation: CLLocation? {
        nil
    }
    var currentHeading: Double {
        0.0
    }
    var breadcrumbHistory: [CLLocationCoordinate2D] {
        []
    }
    var isOffCourse: Bool {
        navigationEngine.currentSnapshot.offRouteStatus == .offRoute || navigationEngine.currentSnapshot.offRouteStatus == .suspected
    }
    var crossTrackErrorMeters: CLLocationDistance {
        navigationEngine.currentSnapshot.crossTrackDistanceMeters ?? 0
    }
    var nextCue: RouteCue? {
        nil
    }
    var distanceToNextCue: CLLocationDistance {
        navigationEngine.currentSnapshot.distanceToNextCueMeters ?? 0
    }
    var currentClimb: ClimbSegment? {
        guard let active = climbEngine.currentSnapshot.activeClimb else { return nil }
        let cat: GPXClimbCategory
        switch active.category {
        case .category4: cat = .cat4
        case .category3: cat = .cat3
        case .category2: cat = .cat2
        case .category1: cat = .cat1
        case .horsCategorie: cat = .hc
        case .uncategorized: cat = .uncategorized
        }
        return ClimbSegment(
            climbIndex: active.climbIndex,
            totalClimbs: active.totalClimbs,
            startDistance: active.startDistanceMeters,
            endDistance: active.endDistanceMeters,
            startElevation: active.startElevationMeters,
            endElevation: active.summitElevationMeters,
            category: cat
        )
    }
    var distanceRemainingInClimb: CLLocationDistance {
        climbEngine.currentSnapshot.distanceRemainingInActiveClimb ?? 0
    }

    // MARK: - Lap Engine
    var laps: [LapRecord] {
        []
    }
    var currentLapDuration: TimeInterval {
        0
    }
    var currentLapDistance: CLLocationDistance {
        0
    }

    // Configuration
    var maxHeartRate: Int = 185
    var isAutoPauseEnabled: Bool = true
    var autoLapDistanceMeters: CLLocationDistance = 5000.0

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
        setupInternalObservers()
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
        setupInternalObservers()
    }

    private func setupInternalObservers() {
        navSubscriptionTask = Task { [weak self] in
            guard let self else { return }
            for await snap in self.navigationEngine.snapshots {
                await self.climbEngine.send(.processNavigation(snap))
            }
        }
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
            _activeRoute = route
            let domainRoute = route.toDomainRoute()
            Task {
                await navigationEngine.send(.useRoute(domainRoute))
                await navigationEngine.send(.start)
                await climbEngine.send(.loadRoute(domainRoute))
            }
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
        WKInterfaceDevice.current().play(.directionUp)
    }

    func finishRide() {
        Task {
            await rideEngine.send(.finish)
            await climbEngine.send(.reset)
        }
    }
}
