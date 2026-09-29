import Foundation
@testable import UltraNav

actor FakeFailureRecorder: FailureRecording {
    private(set) var recordedFailures: [FailureRecord] = []
    private(set) var clearCallCount = 0

    func record(_ record: FailureRecord) async {
        recordedFailures.append(record)
    }

    func recentFailures(limit: Int) async -> [FailureRecord] {
        Array(recordedFailures.suffix(max(0, limit)))
    }

    func clearResolvedFailures() async {
        clearCallCount += 1
        recordedFailures.removeAll()
    }
}
