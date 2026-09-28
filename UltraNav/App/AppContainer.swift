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
        let work = workoutService ?? WorkoutSessionManager.shared
        let sens = sensorService ?? BluetoothSensorManager.shared
        let clk = clock ?? SystemClock()

        let nav = NavigationEngine()
        let met = MetricsEngine()
        let clm = ClimbEngine()

        self.locationService = loc
        self.workoutService = work
        self.sensorService = sens
        self.clock = clk

        self.navigationEngine = nav
        self.metricsEngine = met
        self.climbEngine = clm

        self.rideEngine = RideEngine(
            locationService: loc,
            workoutService: work,
            sensorService: sens,
            clock: clk,
            navigationEngine: nav,
            metricsEngine: met,
            climbEngine: clm
        )
    }
}
