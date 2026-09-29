import Foundation
@testable import UltraNav

@MainActor
final class ClimbEngineBuilder {
    var analysisService: ClimbAnalysisService = ClimbAnalysisService()
    var selector: any ActiveClimbSelecting = StandardActiveClimbSelector()
    var progressCalculator: any ClimbProgressCalculating = StandardClimbProgressCalculator()
    var snapshotBuilder: ClimbSnapshotBuilder = ClimbSnapshotBuilder()

    func withAnalysisService(_ service: ClimbAnalysisService) -> Self {
        self.analysisService = service
        return self
    }

    func withSelector(_ selector: any ActiveClimbSelecting) -> Self {
        self.selector = selector
        return self
    }

    func withProgressCalculator(_ calculator: any ClimbProgressCalculating) -> Self {
        self.progressCalculator = calculator
        return self
    }

    func build() -> ClimbEngine {
        ClimbEngine(
            analysisService: analysisService,
            selector: selector,
            progressCalculator: progressCalculator,
            snapshotBuilder: snapshotBuilder
        )
    }
}
