import Testing
import Foundation
@testable import UltraNav

@Suite("TestLogger Tests")
struct TestLoggerTests {
    @Test("TestLogger captures structured log entries safely")
    func testTestLoggerCapturesEntries() async {
        let logger = TestLogger()

        await logger.information(
            category: .ride,
            "Ride started",
            metadata: [
                LogMetadataEntry(key: "mode", value: .string("outdoor"), privacy: .public)
            ]
        )

        await logger.warning(
            category: .bluetooth,
            "Sensor disconnected",
            metadata: [
                LogMetadataEntry(key: "sensorType", value: .string("heartRate"), privacy: .public)
            ]
        )

        let entries = await logger.entries
        #expect(entries.count == 2)
        #expect(entries[0].level == .information)
        #expect(entries[0].category == .ride)
        #expect(entries[0].message == "Ride started")
        #expect(entries[0].metadata.count == 1)
        #expect(entries[0].metadata[0].key == "mode")

        #expect(entries[1].level == .warning)
        #expect(entries[1].category == .bluetooth)
        #expect(entries[1].message == "Sensor disconnected")

        await logger.clear()
        let cleared = await logger.entries
        #expect(cleared.isEmpty)
    }
}
