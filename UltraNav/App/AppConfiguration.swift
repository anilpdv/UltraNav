import Foundation

struct MetricsFreshnessConfiguration: Equatable, Sendable {
    let freshThresholdSeconds: TimeInterval
    let staleThresholdSeconds: TimeInterval

    init(
        freshThresholdSeconds: TimeInterval = 3.0,
        staleThresholdSeconds: TimeInterval = 10.0
    ) {
        self.freshThresholdSeconds = freshThresholdSeconds
        self.staleThresholdSeconds = staleThresholdSeconds
    }

    static let `default` = MetricsFreshnessConfiguration()
}

struct ClimbConfiguration: Equatable, Sendable {
    let minimumGradientPercent: Double
    let minimumElevationGainMeters: Double

    init(
        minimumGradientPercent: Double = 3.0,
        minimumElevationGainMeters: Double = 15.0
    ) {
        self.minimumGradientPercent = minimumGradientPercent
        self.minimumElevationGainMeters = minimumElevationGainMeters
    }

    static let `default` = ClimbConfiguration()
}

struct AppConfiguration: Equatable, Sendable {
    let environment: AppEnvironment
    let location: LocationConfiguration
    let workout: WorkoutConfiguration
    let rideDependencies: RideDependencyPolicy
    let rideNavigation: RideNavigationPolicy
    let metricsFreshness: MetricsFreshnessConfiguration
    let climb: ClimbConfiguration
    let routeImportLimits: RouteImportLimits
    let routeDirectoryURL: URL?

    init(
        environment: AppEnvironment,
        location: LocationConfiguration = .cycling,
        workout: WorkoutConfiguration = .outdoorCycling,
        rideDependencies: RideDependencyPolicy = .outdoorCycling,
        rideNavigation: RideNavigationPolicy = .default,
        metricsFreshness: MetricsFreshnessConfiguration = .default,
        climb: ClimbConfiguration = .default,
        routeImportLimits: RouteImportLimits = .default,
        routeDirectoryURL: URL? = nil
    ) {
        self.environment = environment
        self.location = location
        self.workout = workout
        self.rideDependencies = rideDependencies
        self.rideNavigation = rideNavigation
        self.metricsFreshness = metricsFreshness
        self.climb = climb
        self.routeImportLimits = routeImportLimits
        self.routeDirectoryURL = routeDirectoryURL
    }

    static let production = AppConfiguration(
        environment: .production
    )

    static let preview = AppConfiguration(
        environment: .preview
    )

    static let test = AppConfiguration(
        environment: .test
    )
}
