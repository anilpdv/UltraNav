import Foundation

struct RecoveryRecommendation: Equatable, Sendable {
    let recoverability: FailureRecoverability
    let actions: [RecoveryAction]
    let automaticRetry: AutomaticRetryPolicy?

    init(
        recoverability: FailureRecoverability,
        actions: [RecoveryAction] = [],
        automaticRetry: AutomaticRetryPolicy? = nil
    ) {
        self.recoverability = recoverability
        self.actions = actions
        self.automaticRetry = automaticRetry
    }
}

protocol RecoveryPolicy: Sendable {
    func recommendation(for failure: UltraNavFailure, context: FailureContext) -> RecoveryRecommendation
}

struct StandardRecoveryPolicy: RecoveryPolicy {
    private let classifier = UltraNavFailureMapper()

    func recommendation(for failure: UltraNavFailure, context: FailureContext) -> RecoveryRecommendation {
        let classification = classifier.classify(failure: failure, context: context)

        let retryPolicy: AutomaticRetryPolicy?
        switch classification.recoverability {
        case .retryable:
            retryPolicy = .immediate
        case .retryableAfterDelay:
            retryPolicy = .sensors
        case .automatic:
            retryPolicy = .location
        default:
            retryPolicy = nil
        }

        return RecoveryRecommendation(
            recoverability: classification.recoverability,
            actions: classification.suggestedActions,
            automaticRetry: retryPolicy
        )
    }
}
