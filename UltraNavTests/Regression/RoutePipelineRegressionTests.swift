import Foundation
import XCTest
@testable import UltraNav

final class RoutePipelineRegressionTests: XCTestCase {
    @MainActor
    func testRoutePipelineStorageAndLoading() async throws {
        let harness = RoutePipelineHarness()
        harness.start()
        
        let route = try await harness.importDefaultRoute()
        let loaded = try await harness.loadRoute(id: route.id)
        
        XCTAssertEqual(loaded.id, route.id)
        XCTAssertEqual(loaded.metadata.name, route.metadata.name)
        
        harness.shutdown()
    }
}
