import CoreLocation
import Foundation

@MainActor
protocol CoreLocationDelegateBridgeDelegate: AnyObject {
    func locationAuthorizationChanged(_ status: CLAuthorizationStatus)
    func locationsReceived(_ locations: [CLLocation])
    func locationUpdateFailed(_ error: Error)
}

final class CoreLocationDelegateBridge: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    weak var delegate: (any CoreLocationDelegateBridgeDelegate)?

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            self?.delegate?.locationAuthorizationChanged(status)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor [weak self] in
            self?.delegate?.locationsReceived(locations)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.delegate?.locationUpdateFailed(error)
        }
    }
}
