import Foundation

/// Delegate protocol for location and heading updates crossing the framework boundary.
@MainActor
protocol LocationServiceDelegate: AnyObject, Sendable {
    func locationService(_ service: any LocationProviding, didUpdateLocation sample: LocationSample)
    func locationService(_ service: any LocationProviding, didUpdateHeading heading: Double)
}

/// Abstract location providing interface for GPS tracking.
@MainActor
protocol LocationProviding: AnyObject {
    var delegate: (any LocationServiceDelegate)? { get set }
    var lastSample: LocationSample? { get }
    var currentHeading: Double { get }

    func requestAuthorization()
    func startUpdating()
    func stopUpdating()
}

