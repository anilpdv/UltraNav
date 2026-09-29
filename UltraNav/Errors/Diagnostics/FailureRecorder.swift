import Foundation

actor FailureRecorder: FailureRecording {
    private let maximumRecords: Int
    private let suppressionPolicy: FailureSuppressionPolicy
    private var records: [FailureRecord] = []
    private var lastRecordedDates: [FailureDeduplicationKey: Date] = [:]
    private var occurrenceCounts: [FailureDeduplicationKey: Int] = [:]

    init(
        maximumRecords: Int = 100,
        suppressionPolicy: FailureSuppressionPolicy = .standard
    ) {
        self.maximumRecords = maximumRecords
        self.suppressionPolicy = suppressionPolicy
    }

    func record(_ record: FailureRecord) async {
        let key = FailureDeduplicationKey(record: record)
        let now = record.context.occurredAt

        let previousCount = occurrenceCounts[key] ?? 0
        let newCount = previousCount + 1
        occurrenceCounts[key] = newCount

        if let lastDate = lastRecordedDates[key] {
            let interval = suppressionPolicy.suppressionInterval(for: record.severity)
            if now.timeIntervalSince(lastDate) < interval {
                // Update occurrence count of existing record if recent
                if let index = records.lastIndex(where: { FailureDeduplicationKey(record: $0) == key }) {
                    let existing = records[index]
                    records[index] = FailureRecord(
                        id: existing.id,
                        failureID: existing.failureID,
                        failure: existing.failure,
                        severity: existing.severity,
                        impact: existing.impact,
                        recoverability: existing.recoverability,
                        suggestedActions: existing.suggestedActions,
                        context: record.context,
                        diagnosticMessage: record.diagnosticMessage ?? existing.diagnosticMessage,
                        occurrenceCount: newCount
                    )
                }
                return
            }
        }

        lastRecordedDates[key] = now

        let updatedRecord = FailureRecord(
            id: record.id,
            failureID: record.failureID,
            failure: record.failure,
            severity: record.severity,
            impact: record.impact,
            recoverability: record.recoverability,
            suggestedActions: record.suggestedActions,
            context: record.context,
            diagnosticMessage: record.diagnosticMessage,
            occurrenceCount: newCount
        )

        records.append(updatedRecord)

        if records.count > maximumRecords {
            records.removeFirst(records.count - maximumRecords)
        }
    }

    func recentFailures(limit: Int) async -> [FailureRecord] {
        Array(records.suffix(max(0, limit)))
    }

    func clearResolvedFailures() async {
        records.removeAll()
        lastRecordedDates.removeAll()
        occurrenceCounts.removeAll()
    }

    func occurrenceCount(for key: FailureDeduplicationKey) -> Int {
        occurrenceCounts[key] ?? 0
    }
}
