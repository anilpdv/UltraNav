import Foundation
import Testing
@testable import UltraNav

@Suite("FailureDeduplication Tests")
struct FailureDeduplicationTests {
    @Test("Repeated failures within suppression window increment count without creating new alerts")
    func testDeduplicationIncrementsCount() async {
        let policy = FailureSuppressionPolicy(informationalSeconds: 10, warningSeconds: 10, highSeconds: 10)
        let recorder = FailureRecorder(maximumRecords: 50, suppressionPolicy: policy)

        let sensorID = SensorIdentifier(rawValue: "cadence-1")
        let baseDate = Date()

        let record1 = FailureFactory.makeRecord(
            failureID: .sensorDisconnected,
            severity: .warning,
            context: FailureContext(occurredAt: baseDate, operation: .sensorMeasurement, sensorID: sensorID)
        )
        await recorder.record(record1)

        let record2 = FailureFactory.makeRecord(
            failureID: .sensorDisconnected,
            severity: .warning,
            context: FailureContext(occurredAt: baseDate.addingTimeInterval(2), operation: .sensorMeasurement, sensorID: sensorID)
        )
        await recorder.record(record2)

        let recent = await recorder.recentFailures(limit: 10)
        #expect(recent.count == 1)
        #expect(recent.first?.occurrenceCount == 2)
    }

    @Test("Failures outside suppression window create separate entries")
    func testOutsideSuppressionWindowCreatesNewEntry() async {
        let policy = FailureSuppressionPolicy(informationalSeconds: 5, warningSeconds: 5, highSeconds: 5)
        let recorder = FailureRecorder(maximumRecords: 50, suppressionPolicy: policy)

        let sensorID = SensorIdentifier(rawValue: "power-1")
        let baseDate = Date()

        let record1 = FailureFactory.makeRecord(
            failureID: .sensorDisconnected,
            severity: .warning,
            context: FailureContext(occurredAt: baseDate, operation: .sensorMeasurement, sensorID: sensorID)
        )
        await recorder.record(record1)

        let record2 = FailureFactory.makeRecord(
            failureID: .sensorDisconnected,
            severity: .warning,
            context: FailureContext(occurredAt: baseDate.addingTimeInterval(10), operation: .sensorMeasurement, sensorID: sensorID)
        )
        await recorder.record(record2)

        let recent = await recorder.recentFailures(limit: 10)
        #expect(recent.count == 2)
    }
}
