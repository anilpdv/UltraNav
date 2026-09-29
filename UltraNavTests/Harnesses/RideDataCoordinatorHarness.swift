import Foundation
@testable import UltraNav

@MainActor
final class RideDataCoordinatorHarness {
    let location: FakeLocationProvider
    let workout: FakeWorkoutProvider
    let sensors: FakeSensorProvider
    let ride: RideEngine
    let metrics: MetricsEngine
    let navigation: NavigationEngine
    let gpsProcessor: GPSProcessor
    let coordinator: RideDataCoordinator
    private let clock: any ClockProviding

    init(
        location: FakeLocationProvider = FakeLocationProvider(),
        workout: FakeWorkoutProvider = FakeWorkoutProvider(),
        sensors: FakeSensorProvider = FakeSensorProvider(),
        gpsProcessor: GPSProcessor = GPSProcessor(),
        clock: any ClockProviding = TestClock()
    ) {
        self.location = location
        self.workout = workout
        self.sensors = sensors
        self.gpsProcessor = gpsProcessor
        self.clock = clock

        self.ride = RideEngine(
            location: location,
            workout: workout,
            sensors: sensors,
            clock: clock,
            dependencyPolicy: .outdoorCycling
        )

        self.metrics = MetricsEngine(
            validator: StandardMetricValidator(),
            sourceSelector: TemporaryLatestSourceSelector(),
            summaryBuilder: MetricsSummaryBuilder(),
            clock: clock
        )

        self.navigation = NavigationEngine(
            routeStore: FakeRouteStore(),
            routeValidator: NavigationRouteValidator(),
            routeMatcher: LegacyRouteMatcher(),
            cueProvider: LegacyCueAdapter(),
            cueProgressor: LegacyCueAdapter(),
            offRouteEvaluator: LegacyOffRouteEvaluator()
        )

        self.coordinator = RideDataCoordinator(
            location: location,
            workout: workout,
            sensors: sensors,
            rideLocationConsumer: ride,
            rideWorkoutConsumer: ride,
            rideSensorConsumer: ride,
            metricsEngine: metrics,
            navigationEngine: navigation,
            gpsProcessor: gpsProcessor,
            clock: clock
        )
    }

    func start() async {
        await gpsProcessor.send(.start(at: clock.now))
        coordinator.activate()
    }

    func shutdown() async {
        coordinator.shutdown()
        location.finishEvents()
        workout.finishEvents()
        sensors.finishEvents()
    }
}
