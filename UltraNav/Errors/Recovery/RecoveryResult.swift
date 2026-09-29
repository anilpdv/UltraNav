import Foundation

enum RecoveryResult: Equatable, Sendable {
    case recovered
    case recoveredWithDegradation(Degradation)
    case retryScheduled(attempt: Int, delaySeconds: TimeInterval)
    case userActionRequired([RecoveryAction])
    case operationAbandoned
    case failed(UltraNavFailure)
}
