import Foundation
@testable import UltraNav

final class FakeRecoveryPolicy: RecoveryPolicy, @unchecked Sendable {
    private let lock = NSLock()
    var customRecommendation: RecoveryRecommendation?
    private(set) var evaluatedFailures: [UltraNavFailure] = []

    init(customRecommendation: RecoveryRecommendation? = nil) {
        self.customRecommendation = customRecommendation
    }

    func setRecommendation(_ recommendation: RecoveryRecommendation?) {
        lock.withLock {
            self.customRecommendation = recommendation
        }
    }

    func recommendation(for failure: UltraNavFailure, context: FailureContext) -> RecoveryRecommendation {
        lock.withLock {
            evaluatedFailures.append(failure)
            if let custom = customRecommendation {
                return custom
            }
            return RecoveryRecommendation(recoverability: .retryable, actions: [.retry])
        }
    }
}
