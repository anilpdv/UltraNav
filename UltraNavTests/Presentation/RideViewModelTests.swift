import XCTest
@testable import UltraNav

@MainActor
final class RideViewModelTests: XCTestCase {
    func testRideViewModelStateTransitionsThroughLifecycle() async {
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

        let viewModel = RideViewModel(rideEngine: ride, lifecycleCoordinator: coordinator)
        XCTAssertEqual(viewModel.state.phase, .idle)
        XCTAssertEqual(viewModel.state.controls.primaryAction, .prepare)

        viewModel.handle(.primaryControlSelected)
        // Wait briefly for Task execution
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(viewModel.state.phase, .ready)
        XCTAssertEqual(viewModel.state.controls.primaryAction, .start)

        viewModel.handle(.primaryControlSelected)
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(viewModel.state.phase, .active)
        XCTAssertEqual(viewModel.state.controls.primaryAction, .pause)
        XCTAssertEqual(viewModel.state.controls.secondaryAction, .finish)

        viewModel.handle(.primaryControlSelected)
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(viewModel.state.phase, .paused)
        XCTAssertEqual(viewModel.state.controls.primaryAction, .resume)

        viewModel.handle(.finishConfirmed)
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(viewModel.state.phase, .completed)
        XCTAssertEqual(viewModel.state.controls.primaryAction, .reset)

        viewModel.handle(.resetSelected)
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(viewModel.state.phase, .idle)
    }
}
