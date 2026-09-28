import CoreLocation
import Foundation

@MainActor
protocol CoreLocationManaging: AnyObject {
    var delegate: CLLocationManagerDelegate? { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var distanceFilter: CLLocationDistance { get set }
    var activityType: CLActivityType { get set }
#if !targetEnvironment(simulator)
    var allowsBackgroundLocationUpdates: Bool { get set }
#endif
    var authorizationStatus: CLAuthorizationStatus { get }

    func requestWhenInUseAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}

extension CLLocationManager: CoreLocationManaging {}
