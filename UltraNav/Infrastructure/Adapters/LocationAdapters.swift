import Foundation
import CoreLocation

// TODO(PHASE-2): Remove after GPX parser and navigation engine use Phase 2 geometry module.
extension Coordinate {
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(_ clCoordinate: CLLocationCoordinate2D) {
        self.init(latitude: clCoordinate.latitude, longitude: clCoordinate.longitude)
    }

    func distance(to other: Coordinate) -> Double {
        let lat1 = latitude * .pi / 180.0
        let lon1 = longitude * .pi / 180.0
        let lat2 = other.latitude * .pi / 180.0
        let lon2 = other.longitude * .pi / 180.0

        let dLat = lat2 - lat1
        let dLon = lon2 - lon1

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1) * cos(lat2) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return 6_371_000.0 * c
    }
}

// TODO(PHASE-1E): Move framework conversions to LocationService.
extension LocationSample {
    init(_ clLocation: CLLocation) {
        let coord = Coordinate(latitude: clLocation.coordinate.latitude, longitude: clLocation.coordinate.longitude)
        let alt = clLocation.verticalAccuracy >= 0 ? clLocation.altitude : nil
        let speed = clLocation.speed >= 0 ? clLocation.speed : nil
        let course = clLocation.course >= 0 ? clLocation.course : nil
        let vertAcc = clLocation.verticalAccuracy >= 0 ? clLocation.verticalAccuracy : nil

        self.init(
            coordinate: coord,
            altitudeMeters: alt,
            horizontalAccuracyMeters: clLocation.horizontalAccuracy,
            verticalAccuracyMeters: vertAcc,
            speedMetersPerSecond: speed,
            courseDegrees: course,
            timestamp: clLocation.timestamp
        )
    }

    var speedKmh: Double? {
        guard let speedMetersPerSecond else { return nil }
        return speedMetersPerSecond * 3.6
    }
}
