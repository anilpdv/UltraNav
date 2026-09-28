import CoreLocation
import XCTest
@testable import UltraNav

final class LocationAuthorizationMappingTests: XCTestCase {
    func testAuthorizationStatusMapping() {
        XCTAssertEqual(LocationAuthorizationStatus(coreLocationStatus: .notDetermined), .notDetermined)
        XCTAssertEqual(LocationAuthorizationStatus(coreLocationStatus: .restricted), .restricted)
        XCTAssertEqual(LocationAuthorizationStatus(coreLocationStatus: .denied), .denied)
        XCTAssertEqual(LocationAuthorizationStatus(coreLocationStatus: .authorizedAlways), .authorized)
        XCTAssertEqual(LocationAuthorizationStatus(coreLocationStatus: .authorizedWhenInUse), .authorized)
    }
}
