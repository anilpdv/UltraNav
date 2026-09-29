import Foundation
import Testing
@testable import UltraNav

@Suite("FailureMapping Tests")
struct FailureMappingTests {
    @Test("UltraNavFailureMapper routes each domain failure to the correct classifier")
    func testTopLevelClassifierRouting() {
        let mapper = UltraNavFailureMapper()
        let context = FailureContext(operation: .appStartup)

        let appClassification = mapper.classify(failure: .app(.dependencyConstructionFailed), context: context)
        #expect(appClassification.id == .appDependencyConstructionFailed)
        #expect(appClassification.severity == .critical)
        #expect(appClassification.recoverability == .fatalForApplication)

        let metricsClassification = mapper.classify(failure: .metrics(.invalidObservation("bad-bpm")), context: context)
        #expect(metricsClassification.id == .metricObservationInvalid)
        #expect(metricsClassification.severity == .informational)

        let climbClassification = mapper.classify(failure: .climb(.noElevationData), context: context)
        #expect(climbClassification.severity == .informational)
        #expect(climbClassification.suggestedActions.contains(.continueWithoutClimbData))
    }
}
