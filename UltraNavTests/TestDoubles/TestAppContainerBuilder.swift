import Foundation
@testable import UltraNav

@MainActor
struct TestAppContainerBuilder {
    var configuration: AppConfiguration = .test
    var clock: any ClockProviding = TestClock()
    var monotonicClock: any MonotonicClockProviding = TestMonotonicClock()
    var logger: any Logging = TestLogger()
    var observability: any ObservabilityProviding = FakeObservabilityCenter()
    var haptics: any HapticProviding = FakeHapticProvider()
    var fileSystem: any RouteFileSystemProviding = FakeRouteFileSystem()

    var location: any LocationProviding = FakeLocationProvider()
    var workout: any WorkoutProviding = FakeWorkoutProvider()
    var sensors: any SensorProviding = FakeSensorProvider()
    var routeStore: any RouteStoring = FakeRouteStore()
    var routeImporter: any RouteImporting = FakeRouteImporter()

    var rideEngine: (any RideEngineProviding)?
    var metricsEngine: (any MetricsEngineProviding)?
    var navigationEngine: (any NavigationEngineProviding)?
    var climbEngine: (any ClimbEngineProviding)?
    var routeLibraryEngine: (any RouteLibraryProviding)?

    var rideLocationConsumer: (any RideLocationEventConsuming)?
    var rideWorkoutConsumer: (any RideWorkoutEventConsuming)?
    var rideSensorConsumer: (any RideSensorEventConsuming)?

    func build() -> AppContainer {
        let infrastructure = InfrastructureDependencies(
            clock: clock,
            monotonicClock: monotonicClock,
            logger: logger,
            observability: observability,
            haptics: haptics,
            fileSystem: fileSystem
        )

        let services = ServiceDependencies(
            location: location,
            workout: workout,
            sensors: sensors,
            routeStore: routeStore,
            routeImporter: routeImporter
        )

        let metrics = metricsEngine ?? MetricsEngine(
            validator: StandardMetricValidator(),
            sourceSelector: TemporaryLatestSourceSelector(),
            summaryBuilder: MetricsSummaryBuilder(),
            clock: clock
        )

        let navigation = navigationEngine ?? NavigationEngine(
            routeStore: routeStore,
            routeValidator: NavigationRouteValidator(),
            routeMatcher: RouteMatcher(),
            cueProvider: NavigationCueBuilder(),
            cueProgressor: CueProgressor(),
            offRouteEvaluator: OffRouteEvaluator()
        )

        let climb = climbEngine ?? ClimbEngine(
            analysisService: ClimbAnalysisService(),
            selector: StandardActiveClimbSelector(),
            progressCalculator: StandardClimbProgressCalculator(),
            snapshotBuilder: ClimbSnapshotBuilder()
        )

        let ride = rideEngine ?? RideEngine(
            location: location,
            workout: workout,
            sensors: sensors,
            clock: clock,
            dependencyPolicy: configuration.rideDependencies
        )

        let routeLibrary = routeLibraryEngine ?? RouteLibraryEngine(
            store: routeStore,
            importer: routeImporter
        )

        let engines = EngineDependencies(
            ride: ride,
            metrics: metrics,
            navigation: navigation,
            climb: climb,
            routeLibrary: routeLibrary
        )

        let locConsumer: any RideLocationEventConsuming = rideLocationConsumer ?? (ride as? RideLocationEventConsuming) ?? (ride as! RideEngine)
        let workConsumer: any RideWorkoutEventConsuming = rideWorkoutConsumer ?? (ride as? RideWorkoutEventConsuming) ?? (ride as! RideEngine)
        let sensConsumer: any RideSensorEventConsuming = rideSensorConsumer ?? (ride as? RideSensorEventConsuming) ?? (ride as! RideEngine)

        let gps = GPSProcessor()

        let rideData = RideDataCoordinator(
            location: location,
            workout: workout,
            sensors: sensors,
            rideLocationConsumer: locConsumer,
            rideWorkoutConsumer: workConsumer,
            rideSensorConsumer: sensConsumer,
            metricsEngine: metrics,
            navigationEngine: navigation,
            gpsProcessor: gps,
            clock: clock
        )

        let rideLifecycle = RideLifecycleCoordinator(
            rideEngine: ride,
            metricsEngine: metrics,
            navigationEngine: navigation,
            climbEngine: climb,
            gpsProcessor: gps,
            clock: clock,
            navigationPolicy: configuration.rideNavigation
        )

        let routeNavigation = RouteNavigationCoordinator(
            routeStore: routeStore,
            routeLibraryEngine: routeLibrary,
            navigationEngine: navigation,
            climbEngine: climb
        )

        let notifications = NavigationNotificationCoordinator(
            navigationEngine: navigation,
            climbEngine: climb,
            haptics: haptics
        )

        let coordinators = CoordinatorDependencies(
            rideData: rideData,
            rideLifecycle: rideLifecycle,
            routeNavigation: routeNavigation,
            notifications: notifications
        )

        let presentation = AppPresentationContainer(
            rideEngine: ride,
            navigationEngine: navigation,
            metricsEngine: metrics,
            climbEngine: climb,
            routeLibraryEngine: routeLibrary,
            lifecycleCoordinator: rideLifecycle,
            routeNavigationCoordinator: routeNavigation
        )

        return AppContainer(
            configuration: configuration,
            infrastructure: infrastructure,
            services: services,
            engines: engines,
            coordinators: coordinators,
            presentation: presentation
        )
    }
}
