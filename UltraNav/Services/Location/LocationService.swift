import CoreLocation
import Foundation
import OSLog

/// CoreLocation wrapper implementing the LocationProviding boundary protocol.
@MainActor
final class LocationService: NSObject, LocationProviding, CoreLocationDelegateBridgeDelegate {
    nonisolated let events: AsyncStream<LocationServiceEvent>
    private let continuation: AsyncStream<LocationServiceEvent>.Continuation

    private let manager: any CoreLocationManaging
    private let delegateBridge: CoreLocationDelegateBridge
    private let converter: any LocationConverting
    private let configuration: LocationConfiguration
    private var state: LocationServiceState = .idle

    init(
        manager: any CoreLocationManaging,
        delegateBridge: CoreLocationDelegateBridge = CoreLocationDelegateBridge(),
        converter: any LocationConverting = CoreLocationSampleConverter(),
        configuration: LocationConfiguration = .cycling
    ) {
        let pair = AsyncStream.makeStream(
            of: LocationServiceEvent.self,
            bufferingPolicy: .bufferingNewest(10)
        )
        self.events = pair.stream
        self.continuation = pair.continuation

        self.manager = manager
        self.delegateBridge = delegateBridge
        self.converter = converter
        self.configuration = configuration

        super.init()

        self.delegateBridge.delegate = self
        self.manager.delegate = self.delegateBridge
        configureManager()
    }

    convenience init(configuration: LocationConfiguration = .cycling) {
        let manager = CLLocationManager()
        let bridge = CoreLocationDelegateBridge()
        let converter = CoreLocationSampleConverter()
        self.init(manager: manager, delegateBridge: bridge, converter: converter, configuration: configuration)
    }

    deinit {
        continuation.finish()
    }

    private func configureManager() {
        manager.desiredAccuracy = configuration.desiredAccuracyMeters
        manager.distanceFilter = configuration.distanceFilterMeters
        manager.activityType = .fitness
#if !targetEnvironment(simulator)
        manager.allowsBackgroundLocationUpdates = configuration.allowsBackgroundUpdates
#endif
    }

    // MARK: - LocationProviding

    func authorizationStatus() async -> LocationAuthorizationStatus {
        LocationAuthorizationStatus(coreLocationStatus: manager.authorizationStatus)
    }

    func requestAuthorization() async {
        let current = await authorizationStatus()
        guard current == .notDetermined else {
            continuation.yield(.authorizationChanged(current))
            return
        }
        manager.requestWhenInUseAuthorization()
    }

    func startUpdates() async throws {
        switch state {
        case .idle, .failed:
            break
        case .starting, .running:
            return
        case .stopping:
            throw LocationServiceFailure.alreadyRunning
        }

        let auth = await authorizationStatus()
        switch auth {
        case .authorized:
            break
        case .denied:
            throw LocationServiceFailure.authorizationDenied
        case .restricted:
            throw LocationServiceFailure.authorizationRestricted
        case .notDetermined:
            throw LocationServiceFailure.updatesUnavailable
        }

        state = .starting
        manager.startUpdatingLocation()
        state = .running
        continuation.yield(.updateStarted)
    }

    func stopUpdates() async {
        switch state {
        case .idle, .stopping:
            return
        case .starting, .running, .failed:
            state = .stopping
            manager.stopUpdatingLocation()
            state = .idle
            continuation.yield(.updateStopped)
        }
    }

    // MARK: - CoreLocationDelegateBridgeDelegate

    func locationAuthorizationChanged(_ status: CLAuthorizationStatus) {
        let authStatus = LocationAuthorizationStatus(coreLocationStatus: status)
        continuation.yield(.authorizationChanged(authStatus))

        switch authStatus {
        case .denied:
            transitionToAuthorizationFailure(.authorizationDenied)
        case .restricted:
            transitionToAuthorizationFailure(.authorizationRestricted)
        case .notDetermined, .authorized:
            break
        }
    }

    func locationsReceived(_ locations: [CLLocation]) {
        guard state == .running else { return }

        for location in locations {
            guard let sample = converter.convert(location) else {
                continue
            }
            // This service emits structurally valid raw samples.
            // Ride-quality filtering belongs to the Phase 3 location-processing pipeline.
            continuation.yield(.locationReceived(sample))
        }
    }

    func locationUpdateFailed(_ error: Error) {
        let failure = mapLocationError(error)
        continuation.yield(.failed(failure))
    }

    private func transitionToAuthorizationFailure(_ failure: LocationServiceFailure) {
        guard state == .starting || state == .running else { return }
        manager.stopUpdatingLocation()
        state = .failed
        continuation.yield(.failed(failure))
    }

    private func mapLocationError(_ error: Error) -> LocationServiceFailure {
        guard let clError = error as? CLError else {
            return .unexpected
        }
        switch clError.code {
        case .denied:
            return .authorizationDenied
        case .locationUnknown:
            return .updatesUnavailable
        default:
            return .updateFailed
        }
    }
}
