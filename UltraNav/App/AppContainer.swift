import Foundation
import SwiftUI

/// Central dependency injection composition root for UltraNav.
@MainActor
@Observable
final class AppContainer {
    let locationService: any LocationProviding
    let workoutService: any WorkoutProviding
    let sensorService: any SensorProviding
    let clock: any ClockProviding

    let navigationEngine: NavigationEngine
    let coordinator: RideNavigationCoordinator
    let metricsEngine: MetricsEngine
    let climbEngine: ClimbEngine
    let rideEngine: RideEngine

    init(
        locationService: (any LocationProviding)? = nil,
        workoutService: (any WorkoutProviding)? = nil,
        sensorService: (any SensorProviding)? = nil,
        clock: (any ClockProviding)? = nil
    ) {
        let loc = locationService ?? LocationService()
        let work = workoutService ?? HealthKitService()
        let sens = sensorService ?? BluetoothService()
        let clk = clock ?? SystemClock()

        let nav = NavigationEngine()
        let met = MetricsEngine()
        let clm = ClimbEngine()

        let ride = RideEngine(
            location: loc,
            workout: work,
            sensors: sens,
            clock: clk
        )

        let coord = RideNavigationCoordinator(
            locationProvider: loc,
            rideConsumer: ride,
            navigationEngine: nav
        )

        self.locationService = loc
        self.workoutService = work
        self.sensorService = sens
        self.clock = clk

        self.navigationEngine = nav
        self.coordinator = coord
        self.metricsEngine = met
        self.climbEngine = clm
        self.rideEngine = ride
    }
}

