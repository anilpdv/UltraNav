import Foundation
import CoreLocation
import OSLog

/// CoreLocation wrapper implementing the LocationProviding boundary protocol.
@MainActor
final class LocationService: NSObject, LocationProviding, CLLocationManagerDelegate {
    public weak var delegate: (any LocationServiceDelegate)?

    private(set) var lastSample: LocationSample?
    private(set) var currentHeading: Double = 0

    private let locationManager: CLLocationManager

    init(locationManager: CLLocationManager = CLLocationManager()) {
        self.locationManager = locationManager
        super.init()
        self.locationManager.delegate = self
        self.locationManager.activityType = .fitness
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.distanceFilter = 2.0
#if !targetEnvironment(simulator)
        self.locationManager.allowsBackgroundLocationUpdates = true
#endif
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let clLocation = locations.last, clLocation.horizontalAccuracy >= 0 else { return }
        let sample = LocationSample(clLocation)
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.lastSample = sample
            self.delegate?.locationService(self, didUpdateLocation: sample)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        let headingVal = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.currentHeading = headingVal
            self.delegate?.locationService(self, didUpdateHeading: headingVal)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        AppLogger.lifecycle.info("Location authorization changed: \(status.rawValue, privacy: .public)")
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        AppLogger.lifecycle.error("Location manager error: \(String(describing: type(of: error)), privacy: .public)")
    }
}
