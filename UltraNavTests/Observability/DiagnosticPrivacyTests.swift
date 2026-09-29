import Testing
import Foundation
@testable import UltraNav

@Suite("DiagnosticPrivacy Tests")
struct DiagnosticPrivacyTests {
    @Test("DiagnosticsCoordinator does not export sensitive coordinates, HR values, or raw keys")
    func testDiagnosticExportPrivacy() async throws {
        let fakeObservability = FakeObservabilityCenter()
        let coordinator = DiagnosticsCoordinator(observability: fakeObservability)

        await fakeObservability.increment(.locationSamplesReceived, by: 42)
        await fakeObservability.setGauge(.connectedSensorCount, value: 1.0)
        await fakeObservability.updateHealth(
            SubsystemHealth(subsystem: .ride, status: .healthy)
        )

        let export = try await coordinator.makeExport()
        #expect(export.contentType == "application/json")
        #expect(export.fileName.hasPrefix("ultranav-diagnostics-"))
        #expect(export.fileName.hasSuffix(".json"))

        let jsonString = String(data: export.data, encoding: .utf8) ?? ""

        // Assert no sensitive health or location data in diagnostic export
        #expect(!jsonString.contains("latitude"))
        #expect(!jsonString.contains("longitude"))
        #expect(!jsonString.contains("heartRate"))
        #expect(!jsonString.contains("watts"))
        #expect(!jsonString.contains("cadence"))
        #expect(!jsonString.contains("gpxContent"))

        // Assert required diagnostic content present
        #expect(jsonString.contains("schemaVersion"))
        #expect(jsonString.contains("locationSamplesReceived"))
        #expect(jsonString.contains("connectedSensorCount"))
        #expect(jsonString.contains("ride"))
        #expect(jsonString.contains("healthy"))
    }
}
