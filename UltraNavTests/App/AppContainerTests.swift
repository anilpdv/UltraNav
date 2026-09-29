import XCTest
@testable import UltraNav

@MainActor
final class AppContainerTests: XCTestCase {

    func testProductionContainerConstruction() throws {
        let container = try AppContainer.makeProduction()

        XCTAssertEqual(container.configuration.environment, .production)
        XCTAssertEqual(container.lifecycle, .created)
        XCTAssertNotNil(container.infrastructure)
        XCTAssertNotNil(container.services)
        XCTAssertNotNil(container.engines)
        XCTAssertNotNil(container.coordinators)
        XCTAssertNotNil(container.presentation)
    }

    func testPreviewContainerConstruction() {
        let container = AppContainer.makePreview()

        XCTAssertEqual(container.configuration.environment, .preview)
        XCTAssertEqual(container.lifecycle, .created)
        XCTAssertNotNil(container.infrastructure)
        XCTAssertNotNil(container.services)
        XCTAssertNotNil(container.engines)
        XCTAssertNotNil(container.coordinators)
        XCTAssertNotNil(container.presentation)
    }

    func testTestContainerBuilderDefaults() {
        let container = TestAppContainerBuilder().build()

        XCTAssertEqual(container.configuration.environment, .test)
        XCTAssertEqual(container.lifecycle, .created)
        XCTAssertNotNil(container.services.location)
        XCTAssertNotNil(container.services.workout)
        XCTAssertNotNil(container.services.sensors)
        XCTAssertNotNil(container.services.routeStore)
        XCTAssertNotNil(container.services.routeImporter)
    }
}
