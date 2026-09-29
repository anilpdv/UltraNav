import Foundation

/// Coordinates location event fan-out and lifecycle policies between RideEngine and NavigationEngine.
@MainActor
final class RideNavigationCoordinator {
    private let locationProvider: any LocationProviding
    private let rideConsumer: any RideLocationConsuming
    private let navigationEngine: any NavigationEngineProviding
    private let policy: RideNavigationPolicy

    private var locationTask: Task<Void, Never>?

    init(
        locationProvider: any LocationProviding,
        rideConsumer: any RideLocationConsuming,
        navigationEngine: any NavigationEngineProviding,
        policy: RideNavigationPolicy = .default
    ) {
        self.locationProvider = locationProvider
        self.rideConsumer = rideConsumer
        self.navigationEngine = navigationEngine
        self.policy = policy
    }

    deinit {
        locationTask?.cancel()
    }

    /// Starts observing location service events and fanning them out to ride and navigation consumers.
    func start() {
        guard locationTask == nil else { return }
        locationTask = Task { [weak self] in
            guard let self else { return }
            for await event in self.locationProvider.events {
                guard !Task.isCancelled else { break }
                self.handleLocationEvent(event)
            }
        }
    }

    /// Stops observing location service events.
    func stop() {
        locationTask?.cancel()
        locationTask = nil
    }

    private func handleLocationEvent(_ event: LocationServiceEvent) {
        // Forward location event to ride engine
        rideConsumer.handle(locationEvent: event)

        // Forward valid location samples to navigation engine
        if case .locationReceived(let sample) = event {
            navigationEngine.consume(location: sample)
        }
    }
}
