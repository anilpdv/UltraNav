import Foundation
@testable import UltraNav

/// Controllable fake location service for unit tests.
@MainActor
public final class FakeLocationService: LocationProviding {
    public weak var delegate: (any LocationServiceDelegate)?

    public var lastSample: LocationSample?
    public var currentHeading: Double = 0

    public var requestAuthorizationCalled: Bool = false
    public var isUpdating: Bool = false

    public init() {}

    public func requestAuthorization() {
        requestAuthorizationCalled = true
    }

    public func startUpdating() {
        isUpdating = true
    }

    public func stopUpdating() {
        isUpdating = false
    }

    public func simulateLocation(_ sample: LocationSample) {
        self.lastSample = sample
        self.delegate?.locationService(self, didUpdateLocation: sample)
    }

    public func simulateHeading(_ heading: Double) {
        self.currentHeading = heading
        self.delegate?.locationService(self, didUpdateHeading: heading)
    }
}
