import XCTest
@testable import UltraNav

final class StoredRouteValidatorTests: XCTestCase {
    private var validator: StoredRouteValidator!

    override func setUp() {
        super.setUp()
        validator = StoredRouteValidator()
    }

    func testValidateEmptyPointsThrows() {
        let route = Route(
            id: RouteID(sha256Hex: "1"),
            metadata: RouteMetadata(name: "Empty"),
            points: [],
            totalDistanceMeters: 0
        )
        XCTAssertThrowsError(try validator.validate(route: route)) { error in
            XCTAssertEqual(error as? RouteValidationFailure, .emptyPoints)
        }
    }

    func testValidateInvalidCoordinatesThrows() {
        let route = Route(
            id: RouteID(sha256Hex: "2"),
            metadata: RouteMetadata(name: "Bad Coord"),
            points: [
                RoutePoint(coordinate: Coordinate(latitude: 37.0, longitude: -122.0), cumulativeDistanceMeters: 0),
                RoutePoint(coordinate: Coordinate(latitude: 100.0, longitude: -122.0), cumulativeDistanceMeters: 100)
            ],
            totalDistanceMeters: 100
        )
        XCTAssertThrowsError(try validator.validate(route: route))
    }

    func testValidateNonMonotonicDistanceThrows() {
        let route = Route(
            id: RouteID(sha256Hex: "3"),
            metadata: RouteMetadata(name: "Non monotonic"),
            points: [
                RoutePoint(coordinate: Coordinate(latitude: 37.0, longitude: -122.0), cumulativeDistanceMeters: 100),
                RoutePoint(coordinate: Coordinate(latitude: 37.01, longitude: -122.0), cumulativeDistanceMeters: 50)
            ],
            totalDistanceMeters: 100
        )
        XCTAssertThrowsError(try validator.validate(route: route)) { error in
            XCTAssertEqual(error as? RouteValidationFailure, .nonMonotonicCumulativeDistances)
        }
    }

    func testValidateValidRouteSucceeds() {
        let route = Route(
            id: RouteID(sha256Hex: "4"),
            metadata: RouteMetadata(name: "Valid"),
            points: [
                RoutePoint(coordinate: Coordinate(latitude: 37.0, longitude: -122.0), cumulativeDistanceMeters: 0),
                RoutePoint(coordinate: Coordinate(latitude: 37.01, longitude: -122.0), cumulativeDistanceMeters: 100)
            ],
            totalDistanceMeters: 100
        )
        XCTAssertNoThrow(try validator.validate(route: route))
    }
}
