import CoreLocation
import Foundation

enum LocationAuthorizationStatus: String, Codable, Sendable {
    case notDetermined
    case restricted
    case denied
    case authorized

    init(coreLocationStatus: CLAuthorizationStatus) {
        switch coreLocationStatus {
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .authorizedAlways, .authorizedWhenInUse:
            self = .authorized
        @unknown default:
            self = .notDetermined
        }
    }
}
