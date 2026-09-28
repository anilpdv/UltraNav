import CoreLocation
import Foundation

struct CoreLocationSampleConverter: LocationConverting, Sendable {

    func convert(_ location: CLLocation) -> LocationSample? {
        let coordinate = Coordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        guard coordinate.isGeographicallyValid else {
            return nil
        }

        guard location.timestamp.timeIntervalSince1970.isFinite else {
            return nil
        }

        let horizontalAccuracy = normalizedHorizontalAccuracy(location.horizontalAccuracy)

        guard let horizontalAccuracy else {
            return nil
        }

        return LocationSample(
            coordinate: coordinate,
            altitudeMeters: normalizedAltitude(location.altitude),
            horizontalAccuracyMeters: horizontalAccuracy,
            verticalAccuracyMeters: normalizedOptionalAccuracy(location.verticalAccuracy),
            speedMetersPerSecond: normalizedNonnegative(location.speed),
            courseDegrees: normalizedCourse(location.course),
            timestamp: location.timestamp
        )
    }
}

private extension CoreLocationSampleConverter {
    func normalizedHorizontalAccuracy(_ value: CLLocationAccuracy) -> Double? {
        guard value.isFinite, value >= 0 else {
            return nil
        }
        return value
    }

    func normalizedOptionalAccuracy(_ value: CLLocationAccuracy) -> Double? {
        guard value.isFinite, value >= 0 else {
            return nil
        }
        return value
    }

    func normalizedNonnegative(_ value: Double) -> Double? {
        guard value.isFinite, value >= 0 else {
            return nil
        }
        return value
    }

    func normalizedAltitude(_ value: Double) -> Double? {
        guard value.isFinite else {
            return nil
        }
        return value
    }

    func normalizedCourse(_ value: CLLocationDirection) -> Double? {
        guard value.isFinite, value >= 0 else {
            return nil
        }

        let normalized = value.truncatingRemainder(dividingBy: 360)
        return normalized >= 0 ? normalized : normalized + 360
    }
}
