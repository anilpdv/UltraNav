import Foundation

enum FailureRecoverability: Equatable, Sendable {
    case automatic
    case userActionRequired
    case retryable
    case retryableAfterDelay
    case recoverableWithDegradation
    case notRecoverableForCurrentOperation
    case fatalForApplication
}
