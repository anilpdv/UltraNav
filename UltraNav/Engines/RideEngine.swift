import Foundation
import WatchKit
import OSLog

/// Central coordinator for ride lifecycle, hardware services, and calculation engines.
@MainActor
@Observable
final class RideEngine: NSObject, LocationServiceDelegate {
    private(set) var state: RideState = .idle
    private(set) var rideSnapshot: RideSnapshot = .initial
    private(set) var navigationSnapshot: NavigationSnapshot = .inactive

    let locationService: any LocationProviding
    let workoutService: any WorkoutProviding
    let sensorService: any SensorProviding
    let clock: any ClockProviding

    let navigationEngine: NavigationEngine
    let metricsEngine: MetricsEngine
    let climbEngine: ClimbEngine

    private var timer: Timer?

    init(
        locationService: any LocationProviding,
        workoutService: any WorkoutProviding,
        sensorService: any SensorProviding,
        clock: any ClockProviding = SystemClock(),
        navigationEngine: NavigationEngine = NavigationEngine(),
        metricsEngine: MetricsEngine = MetricsEngine(),
        climbEngine: ClimbEngine = ClimbEngine()
    ) {
        self.locationService = locationService
        self.workoutService = workoutService
        self.sensorService = sensorService
        self.clock = clock
        self.navigationEngine = navigationEngine
        self.metricsEngine = metricsEngine
        self.climbEngine = climbEngine
        super.init()

        self.locationService.delegate = self
    }

    // MARK: - Ride Lifecycle State Transitions

    func prepareRide(route: GPXRoute? = nil) async throws {
        state = .preparing

        locationService.requestAuthorization()
        let authSuccess = await workoutService.requestAuthorization()
        if !authSuccess {
            state = .failed(failure: .workoutAuthorizationDenied, recovery: .returnToIdle)
            throw RideFailure.workoutAuthorizationDenied
        }

        if let route {
            navigationEngine.load(route: route)
        }

        state = .ready
        updateSnapshots()
    }

    func startRide(route: GPXRoute? = nil) async throws {
        if state == .idle {
            try await prepareRide(route: route)
        }

        state = .active
        AppLogger.lifecycle.info("RideEngine transitioned to .active")

        locationService.startUpdating()
        sensorService.startScanning()

        let workoutStarted: Void? = try? await workoutService.startWorkout()
        if workoutStarted == nil {
            AppLogger.lifecycle.warning("Workout session start failed; continuing offline recording")
        }

        startTimer()
        updateSnapshots()
    }

    func pauseRide() {
        guard state == .active else { return }
        state = .paused
        AppLogger.lifecycle.info("RideEngine transitioned to .paused")

        workoutService.pauseWorkout()
        stopTimer()
        updateSnapshots()
    }

    func resumeRide() {
        guard state == .paused else { return }
        state = .active
        AppLogger.lifecycle.info("RideEngine resumed to .active")

        workoutService.resumeWorkout()
        startTimer()
        updateSnapshots()
    }

    func finishRide() async throws {
        guard state == .active || state == .paused else { return }
        state = .finishing

        stopTimer()
        locationService.stopUpdating()
        sensorService.stopScanning()

        try await workoutService.stopWorkout()
        state = .completed
        AppLogger.lifecycle.info("RideEngine finished and transitioned to .completed")
        updateSnapshots()
    }

    func resetToIdle() {
        stopTimer()
        locationService.stopUpdating()
        sensorService.stopScanning()
        navigationEngine.reset()
        metricsEngine.reset(at: clock.now)
        climbEngine.reset()
        state = .idle
        updateSnapshots()
    }

    func triggerManualLap() {
        guard state == .active else { return }
        let _ = metricsEngine.triggerLap(at: clock.now)
        updateSnapshots()
        WKInterfaceDevice.current().play(.directionUp)
    }

    // MARK: - Timer & Snapshots

    func tick() {
        guard state == .active else { return }
        metricsEngine.updateTimerTick()
        let pwr = sensorService.livePower
        let hr = sensorService.liveHeartRate
        let cad = sensorService.liveCadence.map { Double($0) }
        let spd = sensorService.liveSpeedKmh.map { $0 / 3.6 }

        metricsEngine.updateSensors(
            speedMetersPerSecond: spd,
            heartRate: hr,
            cadenceRPM: cad,
            powerWatts: pwr,
            activeCalories: nil
        )

        updateSnapshots()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - LocationServiceDelegate

    func locationService(_ service: any LocationProviding, didUpdateLocation sample: LocationSample) {
        guard state == .active else { return }

        metricsEngine.update(location: sample)
        navigationEngine.update(location: sample)
        climbEngine.update(
            location: sample,
            totalDistance: metricsEngine.totalDistanceMeters,
            route: navigationEngine.activeRoute
        )

        updateSnapshots()
    }

    func locationService(_ service: any LocationProviding, didUpdateHeading heading: Double) {
        updateSnapshots()
    }

    private func updateSnapshots() {
        self.rideSnapshot = RideSnapshot(
            state: state,
            elapsedTimeSeconds: metricsEngine.elapsedTime,
            movingTimeSeconds: metricsEngine.movingTime,
            metrics: metricsEngine.metrics
        )

        self.navigationSnapshot = navigationEngine.snapshot
    }
}
