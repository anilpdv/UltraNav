import Foundation

@MainActor
public final class AppPresentationContainer {
    public let app: AppViewModel
    public let ride: RideViewModel
    public let metrics: MetricsViewModel
    public let navigation: NavigationViewModel
    public let climb: ClimbViewModel
    public let routes: RouteLibraryViewModel
    public let map: RouteMapViewModel

    public var routeLibrary: RouteLibraryViewModel { routes }

    init(
        app: AppViewModel,
        ride: RideViewModel,
        metrics: MetricsViewModel,
        navigation: NavigationViewModel,
        climb: ClimbViewModel,
        routes: RouteLibraryViewModel,
        map: RouteMapViewModel
    ) {
        self.app = app
        self.ride = ride
        self.metrics = metrics
        self.navigation = navigation
        self.climb = climb
        self.routes = routes
        self.map = map
    }

    convenience init(
        rideEngine: any RideEngineProviding,
        navigationEngine: any NavigationEngineProviding,
        metricsEngine: any MetricsEngineProviding,
        climbEngine: any ClimbEngineProviding,
        routeLibraryEngine: any RouteLibraryProviding,
        lifecycleCoordinator: RideLifecycleCoordinator,
        routeNavigationCoordinator: RouteNavigationCoordinator,
        preferences: UnitPreferences = .default
    ) {
        let rideVM = RideViewModel(
            rideEngine: rideEngine,
            lifecycleCoordinator: lifecycleCoordinator
        )
        let metricsVM = MetricsViewModel(
            metricsEngine: metricsEngine,
            rideEngine: rideEngine,
            preferences: preferences
        )
        let navVM = NavigationViewModel(
            navigationEngine: navigationEngine,
            routeNavigationCoordinator: routeNavigationCoordinator,
            preferences: preferences
        )
        let climbVM = ClimbViewModel(
            climbEngine: climbEngine,
            preferences: preferences
        )
        let routesVM = RouteLibraryViewModel(
            routeLibraryEngine: routeLibraryEngine,
            routeNavigationCoordinator: routeNavigationCoordinator,
            preferences: preferences
        )
        let mapVM = RouteMapViewModel(
            navigationEngine: navigationEngine
        )
        let appVM = AppViewModel(
            ride: rideVM,
            metrics: metricsVM,
            navigation: navVM,
            climb: climbVM,
            routes: routesVM,
            map: mapVM
        )

        self.init(
            app: appVM,
            ride: rideVM,
            metrics: metricsVM,
            navigation: navVM,
            climb: climbVM,
            routes: routesVM,
            map: mapVM
        )
    }
}
