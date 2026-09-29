import Foundation

enum DiagnosticEventKind: Equatable, Sendable {
    case stateTransition(StateTransitionTrace)
    case operationStarted(OperationTrace)
    case operationFinished(OperationTrace)
    case failureRecorded(FailureID)
    case degradationEntered(FailureID)
    case degradationResolved(FailureID)
    case eventDropped(EventDropRecord)
    case inputDiscarded(DiscardedInputRecord)
    case subsystemHealthChanged(SubsystemHealth)
    case custom(String)
}

struct DiagnosticEvent: Identifiable, Equatable, Sendable {
    let id: DiagnosticEventID
    let sequence: UInt64
    let occurredAt: Date
    let category: LogCategory
    let kind: DiagnosticEventKind
    let severity: LogLevel
    let operationID: OperationID?
    let metadata: [DiagnosticMetadata]

    init(
        id: DiagnosticEventID = DiagnosticEventID(),
        sequence: UInt64 = 0,
        occurredAt: Date = Date(),
        category: LogCategory,
        kind: DiagnosticEventKind,
        severity: LogLevel = .information,
        operationID: OperationID? = nil,
        metadata: [DiagnosticMetadata] = []
    ) {
        self.id = id
        self.sequence = sequence
        self.occurredAt = occurredAt
        self.category = category
        self.kind = kind
        self.severity = severity
        self.operationID = operationID
        self.metadata = metadata
    }
}
