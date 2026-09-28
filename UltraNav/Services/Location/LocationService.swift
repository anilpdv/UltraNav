import Foundation
import CoreLocation
import OSLog

/// CoreLocation wrapper implementing the LocationProviding boundary protocol.
@MainActor
final class LocationService: NSObject, LocationProviding, CLLocationManagerDelegate {
    nonisolated let events: AsyncStream<LocationServiceEvent>
    private let continuation: AsyncStream<LocationServiceEvent>.Continuation

    private let locationManager: CLLocationManager

    override init() {
        let pair = AsyncStream.makeStream(of: LocationServiceEvent.self)
        self.events = pair.stream
        self.continuation = pair.continuation
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager.delegate = self
        self.locationManager.activityType = .fitness
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.distanceFilter = 2.0
#if !targetEnvironment(simulator)
        self.locationManager.allowsBackgroundLocationUpdates = true
#endif
    }

    func authorizationStatus() async -> LocationAuthorizationStatus {
        switch locationManager.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorizedAlways, .authorizedWhenInUse: return .authorized
        @unknown default: return .notDetermined
        }
    }

    func requestAuthorization() async {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdates() async throws {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        continuation.yield(.updateStarted)
    }

    func stopUpdates() async {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        continuation.yield(.updateStopped)
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let clLocation = locations.last, clLocation.horizontalAccuracy >= 0 else { return }
        let sample = LocationSample(clLocation)
        continuation.yield(.locationReceived(sample))
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status: LocationAuthorizationStatus
        switch manager.authorizationStatus {
        case .notDetermined: status = .notDetermined
        case .restricted: status = .restricted
        case .denied: status = .denied
        case .authorizedAlways, .authorizedWhenInUse: status = .authorized
        @unknown default: status = .notDetermined
        }
        continuation.yield(.authorizationChanged(status))
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation.yield(.failed(.updateFailed))
    }
}
