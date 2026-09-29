import Foundation

@MainActor
struct InfrastructureDependencies {
    let clock: any ClockProviding
    let haptics: any HapticProviding
    let fileSystem: any RouteFileSystemProviding

    init(
        clock: any ClockProviding,
        haptics: any HapticProviding,
        fileSystem: any RouteFileSystemProviding
    ) {
        self.clock = clock
        self.haptics = haptics
        self.fileSystem = fileSystem
    }
}

@MainActor
struct ServiceDependencies {
    let location: any LocationProviding
    let workout: any WorkoutProviding
    let sensors: any SensorProviding
    let routeStore: any RouteStoring
    let routeImporter: any RouteImporting

    init(
        location: any LocationProviding,
        workout: any WorkoutProviding,
        sensors: any SensorProviding,
        routeStore: any RouteStoring,
        routeImporter: any RouteImporting
    ) {
        self.location = location
        self.workout = workout
        self.sensors = sensors
        self.routeStore = routeStore
        self.routeImporter = routeImporter
    }
}

@MainActor
struct EngineDependencies {
    let ride: any RideEngineProviding
    let metrics: any MetricsEngineProviding
    let navigation: any NavigationEngineProviding
    let climb: any ClimbEngineProviding
    let routeLibrary: any RouteLibraryProviding

    init(
        ride: any RideEngineProviding,
        metrics: any MetricsEngineProviding,
        navigation: any NavigationEngineProviding,
        climb: any ClimbEngineProviding,
        routeLibrary: any RouteLibraryProviding
    ) {
        self.ride = ride
        self.metrics = metrics
        self.navigation = navigation
        self.climb = climb
        self.routeLibrary = routeLibrary
    }
}

@MainActor
struct CoordinatorDependencies {
    let rideData: RideDataCoordinator
    let rideLifecycle: RideLifecycleCoordinator
    let routeNavigation: RouteNavigationCoordinator
    let notifications: NavigationNotificationCoordinator

    init(
        rideData: RideDataCoordinator,
        rideLifecycle: RideLifecycleCoordinator,
        routeNavigation: RouteNavigationCoordinator,
        notifications: NavigationNotificationCoordinator
    ) {
        self.rideData = rideData
        self.rideLifecycle = rideLifecycle
        self.routeNavigation = routeNavigation
        self.notifications = notifications
    }
}
