import Foundation
import XCTest
@testable import UltraNav

/// Focused assertions for Observability and Diagnostics.
func assertDiagnosticEventRecorded(
    in observability: FakeObservabilityCenter,
    id: DiagnosticEventID,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    let events = await observability.recordedEvents
    let matched = events.contains { $0.id == id }
    XCTAssertTrue(matched, "Expected diagnostic event with ID '\(id.rawValue)' to be recorded", file: file, line: line)
}

func assertNoDiagnosticPII(
    in event: DiagnosticEvent,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let piiKeys: Set<String> = ["name", "email", "heartRateExact", "userIdentifier", "token"]
    let foundPII = event.metadata.contains { piiKeys.contains($0.key.rawValue) }
    XCTAssertFalse(foundPII, "Diagnostic event must not contain raw PII in metadata", file: file, line: line)
}
