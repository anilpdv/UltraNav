import XCTest
@testable import UltraNav

@MainActor
final class RideLifecycleCoordinatorTests: XCTestCase {

    func testLifecycleStartCoordinatesRideAndMetrics() async {
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

        let coordinator = RideLifecycleCoordinator(
            rideEngine: ride,
            metricsEngine: metrics,
            navigationEngine: navigation,
            climbEngine: climb,
            clock: clock,
            navigationPolicy: .default
        )

        await coordinator.prepare()
        XCTAssertEqual(ride.currentSnapshot.state, .ready)

        await coordinator.start()
        XCTAssertEqual(ride.currentSnapshot.state, .active)
        XCTAssertEqual(metrics.state, .active)

        await coordinator.pause()
        XCTAssertEqual(ride.currentSnapshot.state, .paused)
        XCTAssertEqual(metrics.state, .paused)

        await coordinator.resume()
        XCTAssertEqual(ride.currentSnapshot.state, .active)
        XCTAssertEqual(metrics.state, .active)

        await coordinator.finish()
        XCTAssertEqual(ride.currentSnapshot.state, .completed)
        XCTAssertEqual(metrics.state, .stopped)

        await coordinator.reset()
        XCTAssertEqual(ride.currentSnapshot.state, .idle)
        XCTAssertEqual(metrics.state, .idle)
    }

    func testLifecycleStartWithNavigationPolicyStartsNavigationIfReady() async {
        let fakeLocation = FakeLocationProvider()
        let fakeWorkout = FakeWorkoutProvider()
        let fakeSensors = FakeSensorProvider()
        let clock = TestClock()

        await fakeLocation.setStubbedAuthorizationStatus(.authorized)
        await fakeWorkout.setStubbedAuthorizationStatus(.authorized)

        let ride = RideEngine(location: fakeLocation, workout: fakeWorkout, sensors: fakeSensors, clock: clock)
        let metrics = MetricsEngine(clock: clock)

        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5)
        let navigation = NavigationEngine()
        await navigation.send(.useRoute(route))
        XCTAssertEqual(navigation.currentSnapshot.state, .ready)

        let climb = ClimbEngine()

        let coordinator = RideLifecycleCoordinator(
            rideEngine: ride,
            metricsEngine: metrics,
            navigationEngine: navigation,
            climbEngine: climb,
            clock: clock,
            navigationPolicy: RideNavigationPolicy(startNavigationWithRide: true)
        )

        await coordinator.prepare()
        await coordinator.start()

        XCTAssertEqual(ride.currentSnapshot.state, .active)
        XCTAssertEqual(navigation.currentSnapshot.state, .navigating)
    }
}
