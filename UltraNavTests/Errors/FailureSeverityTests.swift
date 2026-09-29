import Foundation
import Testing
@testable import UltraNav

@Suite("FailureSeverity Tests")
struct FailureSeverityTests {
    @Test("FailureSeverity maintains proper relative ordering")
    func testSeverityOrdering() {
        #expect(FailureSeverity.informational < FailureSeverity.warning)
        #expect(FailureSeverity.warning < FailureSeverity.high)
        #expect(FailureSeverity.high < FailureSeverity.critical)
    }

    @Test("FailureImpact option sets compose properly")
    func testImpactComposition() {
        var impact: FailureImpact = [.blocksRideStart, .blocksNavigation]
        #expect(impact.contains(.blocksRideStart))
        #expect(impact.contains(.blocksNavigation))
        #expect(!impact.contains(.blocksAppLaunch))

        impact.insert(.blocksAppLaunch)
        #expect(impact.contains(.blocksAppLaunch))
    }
}
