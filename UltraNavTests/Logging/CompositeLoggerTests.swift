import Testing
import Foundation
@testable import UltraNav

@Suite("CompositeLogger Tests")
struct CompositeLoggerTests {
    @Test("CompositeLogger fans out log events to all children")
    func testCompositeLoggerFansOut() async {
        let logger1 = TestLogger()
        let logger2 = TestLogger()
        let composite = CompositeLogger(loggers: [logger1, logger2])

        await composite.log(
            level: .information,
            category: .ride,
            message: "Composite event",
            metadata: []
        )

        let entries1 = await logger1.entries
        let entries2 = await logger2.entries

        #expect(entries1.count == 1)
        #expect(entries2.count == 1)
        #expect(entries1[0].message == "Composite event")
        #expect(entries2[0].message == "Composite event")
    }
}
