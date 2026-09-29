import Foundation
@testable import UltraNav

enum DiagnosticEventFactory {
    static func makeEvent(
        category: LogCategory = .ride,
        kind: DiagnosticEventKind = .custom("test event"),
        severity: LogLevel = .information,
        occurredAt: Date = Date(),
        operationID: OperationID? = nil,
        metadata: [DiagnosticMetadata] = []
    ) -> DiagnosticEvent {
        DiagnosticEvent(
            id: DiagnosticEventID(),
            sequence: 0,
            occurredAt: occurredAt,
            category: category,
            kind: kind,
            severity: severity,
            operationID: operationID,
            metadata: metadata
        )
    }

    static func makeTransitionEvent(
        subsystem: ObservedSubsystem = .ride,
        from: String = "idle",
        event: String = "start",
        to: String = "active"
    ) -> DiagnosticEvent {
        DiagnosticEvent(
            category: .ride,
            kind: .stateTransition(
                StateTransitionTrace(
                    subsystem: subsystem,
                    fromState: from,
                    event: event,
                    toState: to,
                    changedState: true
                )
            ),
            severity: .information
        )
    }
}
