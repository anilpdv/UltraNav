import XCTest
@testable import UltraNav

@MainActor
final class AppViewModelTests: XCTestCase {
    func testAppViewModelTracksActiveRideAndNavigation() async {
        let fakeLocation = FakeLocationProvider()
        let fakeWorkout = FakeWorkoutProvider()
        let fakeSensors = FakeSensorProvider()
        let clock = TestClock()

        await fakeLocation.setStubbedAuthorizationStatus(.authorized)
        await fakeWorkout.setStubbedAuthorizationStatus(.authorized)

        let ride = RideEngine(location: fakeLocation, workout: fakeWorkout, sensors: fakeSensors, clock: clock)
        let metrics = MetricsEngine(clock: clock)
        let navigation = NavigationEngine()
        let climb = ClimbEngine()
        let library = RouteLibraryEngine()
        let store = FakeRouteStore()

        let rideCoordinator = RideLifecycleCoordinator(
            rideEngine: ride,
            metricsEngine: metrics,
            navigationEngine: navigation,
            climbEngine: climb,
            clock: clock,
            navigationPolicy: .default
        )
        let routeCoordinator = RouteNavigationCoordinator(
            routeStore: store,
            routeLibraryEngine: library,
            navigationEngine: navigation,
            climbEngine: climb
        )

        let rideVM = RideViewModel(rideEngine: ride, lifecycleCoordinator: rideCoordinator)
        let metricsVM = MetricsViewModel(metricsEngine: metrics, rideEngine: ride)
        let navVM = NavigationViewModel(navigationEngine: navigation, routeNavigationCoordinator: routeCoordinator)
        let climbVM = ClimbViewModel(climbEngine: climb)
        let routesVM = RouteLibraryViewModel(routeLibraryEngine: library, routeNavigationCoordinator: routeCoordinator)
        let mapVM = RouteMapViewModel(navigationEngine: navigation)

        let appVM = AppViewModel(
            ride: rideVM,
            metrics: metricsVM,
            navigation: navVM,
            climb: climbVM,
            routes: routesVM,
            map: mapVM
        )

        XCTAssertFalse(appVM.isRiding)

        await rideCoordinator.prepare()
        await rideCoordinator.start()
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertTrue(appVM.isRiding)
    }
}
