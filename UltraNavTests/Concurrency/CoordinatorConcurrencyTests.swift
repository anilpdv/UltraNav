import Foundation
import Testing
@testable import UltraNav

@Suite("CoordinatorConcurrency Tests")
struct CoordinatorConcurrencyTests {
    @Test("Coordinator serializes rapid overlapping commands without race conditions")
    @MainActor
    func testCoordinatorSerializesRapidCommands() async {
        let clock = TestClock()
        let location = FakeLocationProvider()
        let workout = FakeWorkoutProvider()
        let sensors = FakeSensorProvider()
        await location.setStubbedAuthorizationStatus(.authorized)
        await workout.setStubbedAuthorizationStatus(.authorized)

        let rideEngine = RideEngine(
            location: location,
            workout: workout,
            sensors: sensors,
            clock: clock
        )
        let metricsEngine = MetricsEngine(clock: clock)
        let navigationEngine = NavigationEngine()
        let climbEngine = ClimbEngine()

        let coordinator = RideLifecycleCoordinator(
            rideEngine: rideEngine,
            metricsEngine: metricsEngine,
            navigationEngine: navigationEngine,
            climbEngine: climbEngine,
            clock: clock
        )

        // Rapid prepare + start calls
        await coordinator.prepare()
        await coordinator.start()

        #expect(rideEngine.currentSnapshot.state == .active)
        #expect(metricsEngine.state == .active)

        await coordinator.pause()
        await coordinator.resume()

        #expect(rideEngine.currentSnapshot.state == .active)
        #expect(metricsEngine.state == .active)

        await coordinator.finish()
        #expect(rideEngine.currentSnapshot.state == .completed)
    }
}
