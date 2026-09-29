import Foundation

extension AppContainer {
    static func makePreview(
        configuration: AppConfiguration = .preview
    ) -> AppContainer {
        let clock = SystemClock()
        let haptics = WatchHapticService()
        let fileSystem = StandardRouteFileSystem()
        let infrastructure = InfrastructureDependencies(
            clock: clock,
            haptics: haptics,
            fileSystem: fileSystem
        )

        let routeStore = RouteStore(fileSystem: fileSystem)
        let routeImporter = RouteImporter()
        let locationService = LocationService(configuration: configuration.location)
        let workoutService = HealthKitService(clock: clock, configuration: configuration.workout)
        let sensorService = BluetoothService(clock: clock)

        let services = ServiceDependencies(
            location: locationService,
            workout: workoutService,
            sensors: sensorService,
            routeStore: routeStore,
            routeImporter: routeImporter
        )

        let metricsEngine = MetricsEngine(clock: clock)
        let navigationEngine = NavigationEngine(routeStore: routeStore)
        let climbEngine = ClimbEngine()
        let rideEngine = RideEngine(
            location: locationService,
            workout: workoutService,
            sensors: sensorService,
            clock: clock,
            dependencyPolicy: configuration.rideDependencies
        )
        let routeLibraryEngine = RouteLibraryEngine(store: routeStore, importer: routeImporter)

        let engines = EngineDependencies(
            ride: rideEngine,
            metrics: metricsEngine,
            navigation: navigationEngine,
            climb: climbEngine,
            routeLibrary: routeLibraryEngine
        )

        let coordinators = CoordinatorDependencies(
            rideData: RideDataCoordinator(
                location: locationService,
                workout: workoutService,
                sensors: sensorService,
                rideLocationConsumer: rideEngine,
                rideWorkoutConsumer: rideEngine,
                rideSensorConsumer: rideEngine,
                metricsEngine: metricsEngine,
                navigationEngine: navigationEngine
            ),
            rideLifecycle: RideLifecycleCoordinator(
                rideEngine: rideEngine,
                metricsEngine: metricsEngine,
                navigationEngine: navigationEngine,
                climbEngine: climbEngine,
                clock: clock,
                navigationPolicy: configuration.rideNavigation
            ),
            routeNavigation: RouteNavigationCoordinator(
                routeStore: routeStore,
                routeLibraryEngine: routeLibraryEngine,
                navigationEngine: navigationEngine,
                climbEngine: climbEngine
            ),
            notifications: NavigationNotificationCoordinator(
                navigationEngine: navigationEngine,
                climbEngine: climbEngine,
                haptics: haptics
            )
        )

        let presentation = AppPresentationContainer(
            rideEngine: rideEngine,
            navigationEngine: navigationEngine,
            metricsEngine: metricsEngine,
            climbEngine: climbEngine,
            routeLibraryEngine: routeLibraryEngine
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
