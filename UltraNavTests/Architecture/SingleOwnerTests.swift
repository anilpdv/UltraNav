import Foundation
import XCTest
@testable import UltraNav

final class SingleOwnerTests: XCTestCase {
    @MainActor
    func testAppContainerIsSoleOwnerOfServicesAndEngines() async {
        let container = AppContainer.makePreview()
        
        // Assert single coordinator group
        XCTAssertNotNil(container.coordinators.rideLifecycle)
        XCTAssertNotNil(container.coordinators.rideData)
        XCTAssertNotNil(container.coordinators.routeNavigation)
        XCTAssertNotNil(container.coordinators.notifications)
        
        // Assert single engine group
        XCTAssertNotNil(container.engines.ride)
        XCTAssertNotNil(container.engines.navigation)
        XCTAssertNotNil(container.engines.metrics)
        XCTAssertNotNil(container.engines.climb)
        XCTAssertNotNil(container.engines.routeLibrary)
        
        // Assert single service group
        XCTAssertNotNil(container.services.location)
        XCTAssertNotNil(container.services.workout)
        XCTAssertNotNil(container.services.sensors)
        XCTAssertNotNil(container.services.routeStore)
        XCTAssertNotNil(container.services.routeImporter)
    }
}
