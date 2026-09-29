import Testing
import Foundation
@testable import UltraNav

@Suite("LogPrivacy Tests")
struct LogPrivacyTests {
    @Test("LogMetadataEntry redacts sensitive values when formatting")
    func testSensitiveValuesRedacted() {
        let publicEntry = LogMetadataEntry(
            key: "subsystem",
            value: .string("location"),
            privacy: .public
        )
        let privateEntry = LogMetadataEntry(
            key: "sensorID",
            value: .identifier("ABC-123"),
            privacy: .privateData
        )
        let sensitiveEntry = LogMetadataEntry(
            key: "heartRate",
            value: .integer(165),
            privacy: .sensitive
        )

        #expect(publicEntry.renderedValue(redactingSensitive: true) == "location")
        #expect(privateEntry.renderedValue(redactingSensitive: true) == "ABC-123")
        #expect(sensitiveEntry.renderedValue(redactingSensitive: true) == "<redacted>")
        #expect(sensitiveEntry.renderedValue(redactingSensitive: false) == "165")
    }
}
