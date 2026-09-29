import Foundation
@testable import UltraNav

/// Spy recording reported failures and tracking recovery resolutions.
actor FailureRecorderSpy {
    private(set) var recordedFailures: [FailureRecord] = []
    private(set) var resolvedFailures: [FailureID] = []

    func record(_ report: FailureRecord) {
        recordedFailures.append(report)
    }

    func resolve(id: FailureID) {
        resolvedFailures.append(id)
    }

    var count: Int {
        recordedFailures.count
    }

    var latest: FailureRecord? {
        recordedFailures.last
    }

    func clear() {
        recordedFailures.removeAll()
        resolvedFailures.removeAll()
    }
}
