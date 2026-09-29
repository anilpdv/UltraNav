import Foundation

enum MetricValidationFailure: Equatable, Sendable {
    case typeMismatch
    case nonFiniteValue
    case belowMinimum
    case aboveMaximum
    case timestampInvalid
    case cumulativeValueDecreased
    case staleAtReceipt
}

enum MetricValidationResult: Equatable, Sendable {
    case accepted(MetricObservation)
    case rejected(MetricValidationFailure)

    var isAccepted: Bool {
        if case .accepted = self { return true }
        return false
    }
}
