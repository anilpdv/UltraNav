import Foundation

@MainActor
final class RideDataCoordinator {
    private let location: any LocationProviding
    private let workout: any WorkoutProviding
    private let sensors: any SensorProviding
    private let rideLocationConsumer: any RideLocationEventConsuming
    private let rideWorkoutConsumer: any RideWorkoutEventConsuming
    private let rideSensorConsumer: any RideSensorEventConsuming
    private let metricsEngine: any MetricsEngineProviding
    private let navigationEngine: any NavigationEngineProviding
    private let gpsProcessor: any GPSProcessing
    private let clock: any ClockProviding

    private var locationTask: Task<Void, Never>?
    private var workoutTask: Task<Void, Never>?
    private var sensorTask: Task<Void, Never>?

    private(set) var isActive = false

    init(
        location: any LocationProviding,
        workout: any WorkoutProviding,
        sensors: any SensorProviding,
        rideLocationConsumer: any RideLocationEventConsuming,
        rideWorkoutConsumer: any RideWorkoutEventConsuming,
        rideSensorConsumer: any RideSensorEventConsuming,
        metricsEngine: any MetricsEngineProviding,
        navigationEngine: any NavigationEngineProviding,
        gpsProcessor: any GPSProcessing = GPSProcessor(),
        clock: any ClockProviding = SystemClock()
    ) {
        self.location = location
        self.workout = workout
        self.sensors = sensors
        self.rideLocationConsumer = rideLocationConsumer
        self.rideWorkoutConsumer = rideWorkoutConsumer
        self.rideSensorConsumer = rideSensorConsumer
        self.metricsEngine = metricsEngine
        self.navigationEngine = navigationEngine
        self.gpsProcessor = gpsProcessor
        self.clock = clock
    }

    func activate() {
        guard !isActive else { return }
        isActive = true

        startLocationConsumer()
        startWorkoutConsumer()
        startSensorConsumer()
    }

    func shutdown() {
        locationTask?.cancel()
        workoutTask?.cancel()
        sensorTask?.cancel()

        locationTask = nil
        workoutTask = nil
        sensorTask = nil

        isActive = false
    }

    // MARK: - Stream Consumers

    private func startLocationConsumer() {
        let events = location.events
        locationTask = Task { [weak self] in
            for await event in events {
                guard let self, !Task.isCancelled else { break }
                await self.handle(locationEvent: event)
            }
        }
    }

    private func startWorkoutConsumer() {
        let events = workout.events
        workoutTask = Task { [weak self] in
            for await event in events {
                guard let self, !Task.isCancelled else { break }
                await self.handle(workoutEvent: event)
            }
        }
    }

    private func startSensorConsumer() {
        let events = sensors.events
        sensorTask = Task { [weak self] in
            for await event in events {
                guard let self, !Task.isCancelled else { break }
                await self.handle(sensorEvent: event)
            }
        }
    }

    // MARK: - Event Fan-out Handlers

    private func handle(locationEvent: LocationServiceEvent) async {
        await rideLocationConsumer.consume(locationEvent: locationEvent)

        guard case .locationReceived(let sample) = locationEvent else {
            if case .failed = locationEvent {
                await gpsProcessor.send(.locationUnavailable(at: clock.now))
            }
            return
        }

        let result = await gpsProcessor.process(sample, receivedAt: clock.now)
        switch result {
        case .accepted(let accepted):
            metricsEngine.consume(.gps(accepted))
            navigationEngine.consume(location: accepted.sample)
        case .rejected, .ignored:
            break
        }
    }

    private func handle(workoutEvent: WorkoutServiceEvent) async {
        await rideWorkoutConsumer.consume(workoutEvent: workoutEvent)

        switch workoutEvent {
        case .heartRateReceived(let bpm, let timestamp):
            metricsEngine.consume(.workout(.heartRate(beatsPerMinute: Double(bpm), timestamp: timestamp)))
        case .activeEnergyReceived(let kcal, let timestamp):
            metricsEngine.consume(.workout(.activeEnergy(kilocalories: kcal, timestamp: timestamp)))
        case .distanceReceived(let meters, let timestamp):
            metricsEngine.consume(.workout(.cyclingDistance(meters: meters, timestamp: timestamp)))
        case .metricReceived(let metric):
            metricsEngine.consume(.workout(metric))
        default:
            break
        }
    }

    private func handle(sensorEvent: SensorServiceEvent) async {
        await rideSensorConsumer.consume(sensorEvent: sensorEvent)

        guard case .sampleReceived(let sensor, let sample) = sensorEvent else {
            return
        }

        metricsEngine.consume(.sensor(sensor: sensor, sample: sample))
    }
}
