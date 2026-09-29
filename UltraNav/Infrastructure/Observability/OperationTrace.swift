import Foundation

enum OperationOutcome: Equatable, Sendable {
    case succeeded
    case failed(FailureID)
    case cancelled
    case superseded
    case degraded
}

struct OperationTrace: Equatable, Sendable {
    let operationID: OperationID
    let operation: ObservedOperation
    let outcome: OperationOutcome?
    let durationMilliseconds: Double?
    let attempt: Int?
    let parentOperationID: OperationID?

    init(
        operationID: OperationID,
        operation: ObservedOperation,
        outcome: OperationOutcome? = nil,
        durationMilliseconds: Double? = nil,
        attempt: Int? = nil,
        parentOperationID: OperationID? = nil
    ) {
        self.operationID = operationID
        self.operation = operation
        self.outcome = outcome
        self.durationMilliseconds = durationMilliseconds
        self.attempt = attempt
        self.parentOperationID = parentOperationID
    }
}
