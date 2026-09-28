import CoreLocation
import Foundation
@testable import UltraNav

@MainActor
final class FakeLocationManager: CoreLocationManaging {
    weak var delegate: CLLocationManagerDelegate?

    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    var distanceFilter: CLLocationDistance = kCLDistanceFilterNone
    var activityType: CLActivityType = .other
    var allowsBackgroundLocationUpdates: Bool = false
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private(set) var authorizationRequestCount: Int = 0
    private(set) var startUpdatingCallCount: Int = 0
    private(set) var stopUpdatingCallCount: Int = 0

    func requestWhenInUseAuthorization() {
        authorizationRequestCount += 1
    }

    func startUpdatingLocation() {
        startUpdatingCallCount += 1
    }

    func stopUpdatingLocation() {
        stopUpdatingCallCount += 1
    }
}
