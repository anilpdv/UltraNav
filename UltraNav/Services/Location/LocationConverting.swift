import CoreLocation
import Foundation

protocol LocationConverting: Sendable {
    func convert(
        _ location: CLLocation
    ) -> LocationSample?
}
