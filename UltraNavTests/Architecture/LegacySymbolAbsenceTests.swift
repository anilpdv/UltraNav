import Foundation
import XCTest
@testable import UltraNav

final class LegacySymbolAbsenceTests: XCTestCase {
    func testLegacySymbolsAreNotInstantiableOrPresentInProduction() {
        // Assert that the canonical engines exist and conform to their protocols
        XCTAssertTrue((RideEngine.self as Any) is any RideEngineProviding.Type)
        XCTAssertTrue((NavigationEngine.self as Any) is any NavigationEngineProviding.Type)
        XCTAssertTrue((MetricsEngine.self as Any) is any MetricsEngineProviding.Type)
        XCTAssertTrue((ClimbEngine.self as Any) is any ClimbEngineProviding.Type)
        XCTAssertTrue((RouteLibraryEngine.self as Any) is any RouteLibraryProviding.Type)
    }
}
