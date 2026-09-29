import Foundation
import XCTest
@testable import UltraNav

final class LayerDirectionTests: XCTestCase {
    @MainActor
    func testDependencyDirectionFlowsFromTopToBottom() async {
        let container = AppContainer.makePreview()
        
        // Presentation consumes ViewModels
        XCTAssertNotNil(container.presentation.ride)
        XCTAssertNotNil(container.presentation.metrics)
        XCTAssertNotNil(container.presentation.navigation)
        XCTAssertNotNil(container.presentation.climb)
        XCTAssertNotNil(container.presentation.routes)
        
        // ViewModels consume Engines
        XCTAssertEqual(container.presentation.ride.state.phase, .idle)
        XCTAssertEqual(container.presentation.navigation.state.phase, .inactive)
        XCTAssertTrue(container.presentation.routes.state.routes.isEmpty)
    }
}
