import Foundation
import Testing
@testable import UltraNav

@Suite("RecoveryCoordinator Tests")
struct RecoveryCoordinatorTests {
    @Test("RecoveryCoordinator executes recovery actions with proper degradation results")
    @MainActor
    func testPerformRecoveryActions() async {
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

        let lifecycleCoordinator = RideLifecycleCoordinator(
            rideEngine: rideEngine,
            metricsEngine: metricsEngine,
            navigationEngine: navigationEngine,
            climbEngine: climbEngine,
            clock: clock
        )

        let routeStore = FakeRouteStore()
        let routeLibraryEngine = RouteLibraryEngine(store: routeStore)
        let routeNavigationCoordinator = RouteNavigationCoordinator(
            routeStore: routeStore,
            routeLibraryEngine: routeLibraryEngine,
            navigationEngine: navigationEngine,
            climbEngine: climbEngine
        )

        let failureRecorder = FakeFailureRecorder()

        let recoveryCoordinator = RecoveryCoordinator(
            rideLifecycle: lifecycleCoordinator,
            routeNavigation: routeNavigationCoordinator,
            sensors: sensors,
            location: location,
            workout: workout,
            failureRecorder: failureRecorder
        )

        let sensorRecord = FailureFactory.makeRecord(
            failureID: .sensorDisconnected,
            failure: .sensors(.disconnectedUnexpectedly(SensorIdentifier(rawValue: "power-1"))),
            suggestedActions: [.continueWithoutSensors]
        )

        let result = await recoveryCoordinator.perform(action: .continueWithoutSensors, for: sensorRecord)
        #expect(result == .recoveredWithDegradation(.sensorsUnavailable))

        let navRecord = FailureFactory.makeRecord(
            failureID: .navigationRouteMissing,
            failure: .navigation(.routeUnavailable),
            suggestedActions: [.continueWithoutNavigation]
        )

        let navResult = await recoveryCoordinator.perform(action: .continueWithoutNavigation, for: navRecord)
        #expect(navResult == .recoveredWithDegradation(.navigationUnavailable))
    }
}
