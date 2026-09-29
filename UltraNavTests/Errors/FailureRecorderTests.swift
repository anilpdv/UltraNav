import Foundation
import Testing
@testable import UltraNav

@Suite("FailureRecorder Tests")
struct FailureRecorderTests {
    @Test("FailureRecorder maintains strict maximum record capacity")
    func testCapacityLimit() async {
        let recorder = FailureRecorder(maximumRecords: 5, suppressionPolicy: FailureSuppressionPolicy(informationalSeconds: 0, warningSeconds: 0, highSeconds: 0))

        for i in 0..<10 {
            let record = FailureFactory.makeRecord(
                failureID: FailureID(rawValue: "FAIL-\(i)"),
                context: FailureContext(occurredAt: Date().addingTimeInterval(Double(i)), operation: .rideStart)
            )
            await recorder.record(record)
        }

        let recent = await recorder.recentFailures(limit: 10)
        #expect(recent.count == 5)
        #expect(recent.first?.failureID.rawValue == "FAIL-5")
        #expect(recent.last?.failureID.rawValue == "FAIL-9")
    }

    @Test("Clear resolved failures flushes all records and tracking")
    func testClearRecords() async {
        let recorder = FailureRecorder(maximumRecords: 10)
        await recorder.record(FailureFactory.makeRecord())

        var recent = await recorder.recentFailures(limit: 10)
        #expect(recent.count == 1)

        await recorder.clearResolvedFailures()
        recent = await recorder.recentFailures(limit: 10)
        #expect(recent.isEmpty)
    }
}
