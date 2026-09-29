import Foundation

@MainActor
final class AppPresentationContainer {
    let ride: LegacyRideEngineAdapter
    let navigation: LegacyNavigationAdapter
    let metrics: LegacyMetricsAdapter
    let climb: LegacyClimbAdapter
    let routeLibrary: LegacyRouteLibraryAdapter

    init(
        ride: LegacyRideEngineAdapter,
        navigation: LegacyNavigationAdapter,
        metrics: LegacyMetricsAdapter,
        climb: LegacyClimbAdapter,
        routeLibrary: LegacyRouteLibraryAdapter
    ) {
        self.ride = ride
        self.navigation = navigation
        self.metrics = metrics
        self.climb = climb
        self.routeLibrary = routeLibrary
    }

    convenience init(
        rideEngine: any RideEngineProviding,
        navigationEngine: any NavigationEngineProviding,
        metricsEngine: any MetricsEngineProviding,
        climbEngine: any ClimbEngineProviding,
        routeLibraryEngine: any RouteLibraryProviding
    ) {
        self.init(
            ride: LegacyRideEngineAdapter(engine: rideEngine),
            navigation: LegacyNavigationAdapter(navigationEngine: navigationEngine),
            metrics: LegacyMetricsAdapter(engine: metricsEngine),
            climb: LegacyClimbAdapter(climbEngine: climbEngine),
            routeLibrary: LegacyRouteLibraryAdapter(libraryEngine: routeLibraryEngine)
        )
    }
}
