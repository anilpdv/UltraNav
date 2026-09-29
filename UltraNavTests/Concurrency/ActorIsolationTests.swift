import Foundation
import Testing
@testable import UltraNav

@Suite("ActorIsolation Tests")
struct ActorIsolationTests {
    @Test("Engine and Coordinators operate safely on MainActor")
    @MainActor
    func testMainActorOperations() async {
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

        await coordinator.prepare()
        #expect(rideEngine.currentSnapshot.state == .ready)

        await coordinator.start()
        #expect(rideEngine.currentSnapshot.state == .active)
        #expect(metricsEngine.state == .active)

        await coordinator.pause()
        #expect(rideEngine.currentSnapshot.state == .paused)
        #expect(metricsEngine.state == .paused)

        await coordinator.finish()
        #expect(rideEngine.currentSnapshot.state == .completed)
        #expect(metricsEngine.state == .stopped)
    }
}
