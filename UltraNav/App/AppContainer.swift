import Foundation
import CoreLocation
import HealthKit
import CoreBluetooth

@MainActor
final class AppContainer {
    let configuration: AppConfiguration
    let infrastructure: InfrastructureDependencies
    let services: ServiceDependencies
    let engines: EngineDependencies
    let coordinators: CoordinatorDependencies
    let presentation: AppPresentationContainer

    private(set) var lifecycle: AppLifecycleState = .created

    init(
        configuration: AppConfiguration,
        infrastructure: InfrastructureDependencies,
        services: ServiceDependencies,
        engines: EngineDependencies,
        coordinators: CoordinatorDependencies,
        presentation: AppPresentationContainer
    ) {
        self.configuration = configuration
        self.infrastructure = infrastructure
        self.services = services
        self.engines = engines
        self.coordinators = coordinators
        self.presentation = presentation
    }

    // MARK: - Lifecycle Management

    func start() async {
        guard lifecycle == .created || lifecycle == .stopped else {
            return
        }

        lifecycle = .starting

        coordinators.rideData.activate()
        coordinators.routeNavigation.activate()
        coordinators.notifications.activate()

        await engines.routeLibrary.send(.refresh)

        lifecycle = .running
    }

    func stop() async {
        guard lifecycle == .running else {
            return
        }

        lifecycle = .stopping

        coordinators.notifications.shutdown()
        coordinators.routeNavigation.shutdown()
        coordinators.rideData.shutdown()

        await services.location.stopUpdates()
        await services.sensors.stopScanning()

        lifecycle = .stopped
    }

    // MARK: - Production Composition Root Factory

    static func makeProduction(
        configuration: AppConfiguration = .production
    ) throws -> AppContainer {
        // 1. Infrastructure
        let clock = SystemClock()
        let monotonicClock = SystemMonotonicClock()
        let logger = SystemLogger()
        let observability = ObservabilityCenter(clock: clock, logger: logger)
        let haptics = WatchHapticService()
        let fileSystem = StandardRouteFileSystem()
        let infrastructure = InfrastructureDependencies(
            clock: clock,
            monotonicClock: monotonicClock,
            logger: logger,
            observability: observability,
            haptics: haptics,
            fileSystem: fileSystem
        )

        // 2. Persistence & Route Import Pipeline
        let routeCodec = JSONRouteStorageCodec()
        let routeStore = RouteStore(
            storageDirectory: configuration.routeDirectoryURL,
            fileSystem: fileSystem,
            codec: routeCodec
        )

        let routeSourceReader = StandardRouteSourceReader()
        let gpxParser = GPXParserAdapter()
        let parsedRouteValidator = ParsedRouteValidator()
        let routeNormalizer = RouteNormalizer(
            distanceCalculator: CoreLocationDistanceCalculator(),
            identityCreator: SHA256RouteIdentityCreator()
        )
        let storedRouteValidator = StoredRouteValidator()

        let routeImporter = RouteImporter(
            sourceReader: routeSourceReader,
            parser: gpxParser,
            parsedValidator: parsedRouteValidator,
            normalizer: routeNormalizer,
            routeValidator: storedRouteValidator
        )

        // 3. Platform Services
        let locationService = LocationService(
            configuration: configuration.location
        )
        let workoutService = HealthKitService(
            clock: clock,
            configuration: configuration.workout
        )
        let sensorService = BluetoothService(
            clock: clock
        )

        let services = ServiceDependencies(
            location: locationService,
            workout: workoutService,
            sensors: sensorService,
            routeStore: routeStore,
            routeImporter: routeImporter
        )

        // 4. Domain Engines
        let metricsEngine = MetricsEngine(
            validator: StandardMetricValidator(),
            sourceSelector: TemporaryLatestSourceSelector(),
            summaryBuilder: MetricsSummaryBuilder(),
            clock: clock
        )

        let navigationEngine = NavigationEngine(
            routeStore: routeStore,
            routeValidator: NavigationRouteValidator(),
            routeMatcher: LegacyRouteMatcher(),
            cueProvider: LegacyCueAdapter(),
            cueProgressor: LegacyCueAdapter(),
            offRouteEvaluator: LegacyOffRouteEvaluator()
        )

        let climbEngine = ClimbEngine(
            analysisService: ClimbAnalysisService(),
            selector: StandardActiveClimbSelector(),
            progressCalculator: StandardClimbProgressCalculator(),
            snapshotBuilder: ClimbSnapshotBuilder()
        )

        let rideEngine = RideEngine(
            location: locationService,
            workout: workoutService,
            sensors: sensorService,
            clock: clock,
            dependencyPolicy: configuration.rideDependencies
        )

        let routeLibraryEngine = RouteLibraryEngine(
            store: routeStore,
            importer: routeImporter
        )

        let engines = EngineDependencies(
            ride: rideEngine,
            metrics: metricsEngine,
            navigation: navigationEngine,
            climb: climbEngine,
            routeLibrary: routeLibraryEngine
        )

        // 5. Coordinators
        let rideDataCoordinator = RideDataCoordinator(
            location: locationService,
            workout: workoutService,
            sensors: sensorService,
            rideLocationConsumer: rideEngine,
            rideWorkoutConsumer: rideEngine,
            rideSensorConsumer: rideEngine,
            metricsEngine: metricsEngine,
            navigationEngine: navigationEngine
        )

        let rideLifecycleCoordinator = RideLifecycleCoordinator(
            rideEngine: rideEngine,
            metricsEngine: metricsEngine,
            navigationEngine: navigationEngine,
            climbEngine: climbEngine,
            clock: clock,
            navigationPolicy: configuration.rideNavigation
        )

        let routeNavigationCoordinator = RouteNavigationCoordinator(
            routeStore: routeStore,
            routeLibraryEngine: routeLibraryEngine,
            navigationEngine: navigationEngine,
            climbEngine: climbEngine
        )

        let notificationCoordinator = NavigationNotificationCoordinator(
            navigationEngine: navigationEngine,
            climbEngine: climbEngine,
            haptics: haptics
        )

        let coordinators = CoordinatorDependencies(
            rideData: rideDataCoordinator,
            rideLifecycle: rideLifecycleCoordinator,
            routeNavigation: routeNavigationCoordinator,
            notifications: notificationCoordinator
        )

        // 6. Presentation Container
        let presentation = AppPresentationContainer(
            rideEngine: rideEngine,
            navigationEngine: navigationEngine,
            metricsEngine: metricsEngine,
            climbEngine: climbEngine,
            routeLibraryEngine: routeLibraryEngine,
            lifecycleCoordinator: rideLifecycleCoordinator,
            routeNavigationCoordinator: routeNavigationCoordinator
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
