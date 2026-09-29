import XCTest
@testable import UltraNav

final class AppEnvironmentTests: XCTestCase {

    func testAppEnvironmentValues() {
        XCTAssertEqual(AppEnvironment.production.rawValue, "production")
        XCTAssertEqual(AppEnvironment.test.rawValue, "test")
        XCTAssertEqual(AppEnvironment.preview.rawValue, "preview")
    }

    func testConfigurationEnvironments() {
        XCTAssertEqual(AppConfiguration.production.environment, .production)
        XCTAssertEqual(AppConfiguration.test.environment, .test)
        XCTAssertEqual(AppConfiguration.preview.environment, .preview)
    }

    func testLifecycleStateValues() {
        XCTAssertEqual(AppLifecycleState.created.rawValue, "created")
        XCTAssertEqual(AppLifecycleState.starting.rawValue, "starting")
        XCTAssertEqual(AppLifecycleState.running.rawValue, "running")
        XCTAssertEqual(AppLifecycleState.stopping.rawValue, "stopping")
        XCTAssertEqual(AppLifecycleState.stopped.rawValue, "stopped")
        XCTAssertEqual(AppLifecycleState.failed.rawValue, "failed")
    }
}
