import XCTest
@testable import UltraNav

final class CoordinateTests: XCTestCase {
    func testValidCoordinateIsAccepted() {
        let coordinate = Coordinate(
            latitude: 24.7136,
            longitude: 46.6753
        )

        XCTAssertTrue(coordinate.isGeographicallyValid)
    }

    func testLatitudeAboveNinetyIsInvalid() {
        let coordinate = Coordinate(
            latitude: 90.1,
            longitude: 0
        )

        XCTAssertFalse(coordinate.isGeographicallyValid)
    }

    func testLatitudeBelowNegativeNinetyIsInvalid() {
        let coordinate = Coordinate(
            latitude: -90.1,
            longitude: 0
        )

        XCTAssertFalse(coordinate.isGeographicallyValid)
    }

    func testLongitudeOutsideRangeIsInvalid() {
        let coordinate = Coordinate(
            latitude: 0,
            longitude: 180.1
        )

        XCTAssertFalse(coordinate.isGeographicallyValid)
    }

    func testNonFiniteCoordinateIsInvalid() {
        let coordinate = Coordinate(
            latitude: .nan,
            longitude: 46
        )

        XCTAssertFalse(coordinate.isGeographicallyValid)
    }
}
