import Foundation
import WatchKit
import OSLog

/// Central coordinator for ride lifecycle, hardware services, and calculation engines.
@MainActor
@Observable
final class RideEngine: NSObject {
    private(set) var state: RideState = .idle
    private(set) var rideSnapshot: RideSnapshot = .initial
    private(set) var navigationSnapshot: NavigationSnapshot = .inactive

    private(set) var lastSample: LocationSample?
    private(set) var currentHeading: Double = 0.0

    let locationService: any LocationProviding
    let workoutService: any WorkoutProviding
    let sensorService: any SensorProviding
    let clock: any ClockProviding

    let navigationEngine: NavigationEngine
    let metricsEngine: MetricsEngine
    let climbEngine: ClimbEngine

    private var timer: Timer?
    private var locationTask: Task<Void, Never>?
    private var workoutTask: Task<Void, Never>?
    private var sensorTask: Task<Void, Never>?

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
    }

    // MARK: - Ride Lifecycle State Transitions

    func prepareRide(route: GPXRoute? = nil) async throws {
        state = .preparing

        await locationService.requestAuthorization()
        do {
            try await workoutService.requestAuthorization()
            try await workoutService.prepare()
        } catch {
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

        try? await locationService.startUpdates()
        try? await sensorService.startScanning(for: [.cyclingPower, .heartRate, .cyclingCadence, .cyclingSpeed])

        do {
            try await workoutService.start(at: clock.now)
        } catch {
            AppLogger.lifecycle.warning("Workout session start failed; continuing offline recording")
        }

        startEventStreams()
        startTimer()
        updateSnapshots()
    }

    func pauseRide() {
        guard state == .active else { return }
        state = .paused
        AppLogger.lifecycle.info("RideEngine transitioned to .paused")

        Task {
            try? await workoutService.pause()
        }
        stopTimer()
        updateSnapshots()
    }

    func resumeRide() {
        guard state == .paused else { return }
        state = .active
        AppLogger.lifecycle.info("RideEngine resumed to .active")

        Task {
            try? await workoutService.resume()
        }
        startTimer()
        updateSnapshots()
    }

    func finishRide() async throws {
        guard state == .active || state == .paused else { return }
        state = .finishing

        stopTimer()
        stopEventStreams()

        await locationService.stopUpdates()
        await sensorService.stopScanning()

        try? await workoutService.finish(at: clock.now)
        state = .completed
        AppLogger.lifecycle.info("RideEngine finished and transitioned to .completed")
        updateSnapshots()
    }

    func resetToIdle() {
        stopTimer()
        stopEventStreams()

        Task {
            await locationService.stopUpdates()
            await sensorService.stopScanning()
            await workoutService.reset()
        }

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

    // MARK: - Stream Observers

    private func startEventStreams() {
        locationTask?.cancel()
        locationTask = Task { [weak self] in
            guard let self else { return }
            for await event in self.locationService.events {
                guard !Task.isCancelled else { break }
                if case .locationReceived(let sample) = event {
                    self.processLocation(sample)
                }
            }
        }

        workoutTask?.cancel()
        workoutTask = Task { [weak self] in
            guard let self else { return }
            for await event in self.workoutService.events {
                guard !Task.isCancelled else { break }
                switch event {
                case .heartRateReceived(let bpm, _):
                    self.metricsEngine.updateSensors(heartRate: bpm)
                    self.updateSnapshots()
                case .activeEnergyReceived(let kcal, _):
                    self.metricsEngine.updateSensors(activeCalories: Int(kcal))
                    self.updateSnapshots()
                default:
                    break
                }
            }
        }

        sensorTask?.cancel()
        sensorTask = Task { [weak self] in
            guard let self else { return }
            for await event in self.sensorService.events {
                guard !Task.isCancelled else { break }
                if case .sampleReceived(_, let sample) = event {
                    switch sample {
                    case .power(let watts, _):
                        self.metricsEngine.updateSensors(powerWatts: watts)
                    case .cadence(let rpm, _):
                        self.metricsEngine.updateSensors(cadenceRPM: rpm)
                    case .heartRate(let bpm, _):
                        self.metricsEngine.updateSensors(heartRate: bpm)
                    case .speed(let mps, _):
                        self.metricsEngine.updateSensors(speedMetersPerSecond: mps)
                    }
                    self.updateSnapshots()
                }
            }
        }
    }

    private func stopEventStreams() {
        locationTask?.cancel()
        locationTask = nil
        workoutTask?.cancel()
        workoutTask = nil
        sensorTask?.cancel()
        sensorTask = nil
    }

    private func processLocation(_ sample: LocationSample) {
        guard state == .active else { return }
        self.lastSample = sample
        if let course = sample.courseDegrees {
            self.currentHeading = course
        }
        metricsEngine.update(location: sample)
        navigationEngine.update(location: sample)
        climbEngine.update(
            location: sample,
            totalDistance: metricsEngine.totalDistanceMeters,
            route: navigationEngine.activeRoute
        )
        updateSnapshots()
    }

    // MARK: - Timer & Snapshots

    func tick() {
        guard state == .active else { return }
        metricsEngine.updateTimerTick()
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
