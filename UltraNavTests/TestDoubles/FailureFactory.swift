import Foundation
@testable import UltraNav

struct FailureFactory {
    static func makeRecord(
        id: UUID = UUID(),
        failureID: FailureID = .sensorDisconnected,
        failure: UltraNavFailure = .sensors(.disconnectedUnexpectedly(SensorIdentifier(rawValue: "power-1"))),
        severity: FailureSeverity = .warning,
        impact: FailureImpact = .degradesActiveRide,
        recoverability: FailureRecoverability = .retryable,
        suggestedActions: [RecoveryAction] = [.reconnectSensor(SensorIdentifier(rawValue: "power-1")), .continueWithoutSensors],
        context: FailureContext = FailureContext(
            occurredAt: Date(),
            operation: .sensorConnection,
            rideState: .active,
            sensorID: SensorIdentifier(rawValue: "power-1")
        ),
        diagnosticMessage: String? = "Test failure diagnostic",
        occurrenceCount: Int = 1
    ) -> FailureRecord {
        FailureRecord(
            id: id,
            failureID: failureID,
            failure: failure,
            severity: severity,
            impact: impact,
            recoverability: recoverability,
            suggestedActions: suggestedActions,
            context: context,
            diagnosticMessage: diagnosticMessage,
            occurrenceCount: occurrenceCount
        )
    }
}
