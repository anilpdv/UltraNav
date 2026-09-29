import Foundation
@testable import UltraNav

@MainActor
final class UltraNavIntegrationHarness {
    let clock: TestClock
    let monotonicClock: TestMonotonicClock
    let ticker: ManualTicker
    let location: FakeLocationProvider
    let workout: FakeWorkoutProvider
    let sensors: FakeSensorProvider
    let routes: FakeRouteStore
    let importer: FakeRouteImporter
    let haptics: FakeHapticProvider
    let logger: TestLogger
    let observability: FakeObservabilityCenter
    let container: AppContainer

    init(configuration: AppConfiguration = .test) {
        let clock = TestClock(now: TestDates.rideStart)
        let monotonicClock = TestMonotonicClock()
        let ticker = ManualTicker()
        let location = FakeLocationProvider()
        let workout = FakeWorkoutProvider()
        let sensors = FakeSensorProvider()
        let routes = FakeRouteStore()
        let importer = FakeRouteImporter()
        let haptics = FakeHapticProvider()
        let logger = TestLogger()
        let observability = FakeObservabilityCenter()

        self.clock = clock
        self.monotonicClock = monotonicClock
        self.ticker = ticker
        self.location = location
        self.workout = workout
        self.sensors = sensors
        self.routes = routes
        self.importer = importer
        self.haptics = haptics
        self.logger = logger
        self.observability = observability

        let builder = TestAppContainerBuilder(
            configuration: configuration,
            clock: clock,
            monotonicClock: monotonicClock,
            logger: logger,
            observability: observability,
            haptics: haptics,
            location: location,
            workout: workout,
            sensors: sensors,
            routeStore: routes,
            routeImporter: importer
        )

        self.container = builder.build()
    }

    /// Starts all container lifecycle and coordination pipelines.
    func start() async {
        await container.start()
    }

    /// Shuts down all engines, coordinators, and test services cleanly.
    func shutdown() async {
        await container.stop()
        await ticker.stop()
        location.finishEvents()
        workout.finishEvents()
        sensors.finishEvents()
    }

    /// Authorizes all services to .authorized state.
    func authorizeAllServices() async {
        await location.setStubbedAuthorizationStatus(.authorized)
        await workout.setStubbedAuthorizationStatus(.authorized)
        await sensors.setStubbedIsAvailable(true)
    }

    /// Prepares ride with all dependencies verified.
    func prepareRideSuccessfully() async throws {
        await authorizeAllServices()
        await container.coordinators.rideLifecycle.prepare()
    }

    /// Starts ride and advances clock deterministically.
    func startRideSuccessfully() async throws {
        await container.coordinators.rideLifecycle.start()
    }

    /// Pauses active ride.
    func pauseRideSuccessfully() async throws {
        await container.coordinators.rideLifecycle.pause()
    }

    /// Resumes paused ride.
    func resumeRideSuccessfully() async throws {
        await container.coordinators.rideLifecycle.resume()
    }

    /// Finishes ride cleanly.
    func finishRideSuccessfully() async throws {
        await container.coordinators.rideLifecycle.finish()
    }

    /// Loads a route into the store and starts navigation on it.
    func loadAndStartRoute(_ route: Route) async throws {
        _ = try await routes.saveRoute(route, behavior: .overwriteExisting)
        await container.coordinators.routeNavigation.selectRoute(id: route.id)
        await container.engines.navigation.send(.start)
    }
}
