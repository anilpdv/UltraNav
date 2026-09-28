import CoreLocation
import XCTest
@testable import UltraNav

final class CoreLocationSampleConverterTests: XCTestCase {

    private let converter = CoreLocationSampleConverter()

    func testValidLocationConvertsToDomainSample() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 24.7136,
                longitude: 46.6753
            ),
            altitude: 600,
            horizontalAccuracy: 5,
            verticalAccuracy: 8,
            course: 90,
            speed: 7,
            timestamp: date
        )

        let sample = try XCTUnwrap(converter.convert(location))

        XCTAssertEqual(sample.coordinate.latitude, 24.7136, accuracy: 0.000_001)
        XCTAssertEqual(sample.coordinate.longitude, 46.6753, accuracy: 0.000_001)
        XCTAssertEqual(sample.altitudeMeters, 600)
        XCTAssertEqual(sample.horizontalAccuracyMeters, 5)
        XCTAssertEqual(sample.verticalAccuracyMeters, 8)
        XCTAssertEqual(sample.courseDegrees, 90)
        XCTAssertEqual(sample.speedMetersPerSecond, 7)
        XCTAssertEqual(sample.timestamp, date)
    }

    func testNegativeSpeedBecomesNil() throws {
        let location = makeLocation(speed: -1)
        let sample = try XCTUnwrap(converter.convert(location))
        XCTAssertNil(sample.speedMetersPerSecond)
    }

    func testNegativeCourseBecomesNil() throws {
        let location = makeLocation(course: -1)
        let sample = try XCTUnwrap(converter.convert(location))
        XCTAssertNil(sample.courseDegrees)
    }

    func testNegativeVerticalAccuracyBecomesNil() throws {
        let location = makeLocation(verticalAccuracy: -1)
        let sample = try XCTUnwrap(converter.convert(location))
        XCTAssertNil(sample.verticalAccuracyMeters)
    }

    func testNegativeHorizontalAccuracyRejectsSample() {
        let location = makeLocation(horizontalAccuracy: -1)
        XCTAssertNil(converter.convert(location))
    }

    func testInvalidCoordinateRejectsSample() {
        let location = makeLocation(latitude: 95.0, longitude: 46.6753)
        XCTAssertNil(converter.convert(location))
    }

    func testCourseNormalization() throws {
        let location = makeLocation(course: 450)
        let sample = try XCTUnwrap(converter.convert(location))
        XCTAssertEqual(sample.courseDegrees, 90)
    }
}

private extension CoreLocationSampleConverterTests {
    func makeLocation(
        latitude: Double = 24.7136,
        longitude: Double = 46.6753,
        altitude: Double = 600,
        horizontalAccuracy: Double = 5,
        verticalAccuracy: Double = 8,
        course: Double = 90,
        speed: Double = 7,
        timestamp: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude
            ),
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            course: course,
            speed: speed,
            timestamp: timestamp
        )
    }
}
