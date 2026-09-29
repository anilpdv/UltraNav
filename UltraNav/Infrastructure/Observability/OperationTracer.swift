import Foundation

struct OperationTracer: Sendable {
    private let observability: any ObservabilityProviding
    private let monotonicClock: any MonotonicClockProviding
    private let clock: any ClockProviding

    init(
        observability: any ObservabilityProviding,
        monotonicClock: any MonotonicClockProviding = SystemMonotonicClock(),
        clock: any ClockProviding = SystemClock()
    ) {
        self.observability = observability
        self.monotonicClock = monotonicClock
        self.clock = clock
    }

    func trace<T: Sendable>(
        operation: ObservedOperation,
        operationID: OperationID = OperationID(),
        parentOperationID: OperationID? = nil,
        attempt: Int? = nil,
        category: LogCategory = .app,
        body: @Sendable () async throws -> T
    ) async throws -> T {
        let startEvent = DiagnosticEvent(
            occurredAt: clock.now,
            category: category,
            kind: .operationStarted(
                OperationTrace(
                    operationID: operationID,
                    operation: operation,
                    outcome: nil,
                    durationMilliseconds: nil,
                    attempt: attempt,
                    parentOperationID: parentOperationID
                )
            ),
            severity: .information,
            operationID: operationID,
            metadata: [
                DiagnosticMetadata(key: .operation, value: .string(operation.rawValue), privacy: .public)
            ]
        )
        await observability.record(startEvent)

        let startInstant = monotonicClock.now
        do {
            let result = try await body()
            let endInstant = monotonicClock.now
            let duration = monotonicClock.duration(from: startInstant, to: endInstant)
            let durationMs = Double(duration.components.seconds) * 1000.0 + Double(duration.components.attoseconds) / 1_000_000_000_000_000.0

            let finishEvent = DiagnosticEvent(
                occurredAt: clock.now,
                category: category,
                kind: .operationFinished(
                    OperationTrace(
                        operationID: operationID,
                        operation: operation,
                        outcome: .succeeded,
                        durationMilliseconds: durationMs,
                        attempt: attempt,
                        parentOperationID: parentOperationID
                    )
                ),
                severity: .information,
                operationID: operationID,
                metadata: [
                    DiagnosticMetadata(key: .operation, value: .string(operation.rawValue), privacy: .public),
                    DiagnosticMetadata(key: .durationMilliseconds, value: .durationMilliseconds(durationMs), privacy: .public)
                ]
            )
            await observability.record(finishEvent)
            return result
        } catch is CancellationError {
            let endInstant = monotonicClock.now
            let duration = monotonicClock.duration(from: startInstant, to: endInstant)
            let durationMs = Double(duration.components.seconds) * 1000.0 + Double(duration.components.attoseconds) / 1_000_000_000_000_000.0

            let finishEvent = DiagnosticEvent(
                occurredAt: clock.now,
                category: category,
                kind: .operationFinished(
                    OperationTrace(
                        operationID: operationID,
                        operation: operation,
                        outcome: .cancelled,
                        durationMilliseconds: durationMs,
                        attempt: attempt,
                        parentOperationID: parentOperationID
                    )
                ),
                severity: .notice,
                operationID: operationID,
                metadata: [
                    DiagnosticMetadata(key: .operation, value: .string(operation.rawValue), privacy: .public),
                    DiagnosticMetadata(key: .durationMilliseconds, value: .durationMilliseconds(durationMs), privacy: .public)
                ]
            )
            await observability.record(finishEvent)
            throw CancellationError()
        } catch {
            let endInstant = monotonicClock.now
            let duration = monotonicClock.duration(from: startInstant, to: endInstant)
            let durationMs = Double(duration.components.seconds) * 1000.0 + Double(duration.components.attoseconds) / 1_000_000_000_000_000.0

            let failureID: FailureID
            if let customFailure = error as? (any CustomStringConvertible) {
                failureID = FailureID(rawValue: "\(customFailure)")
            } else {
                failureID = FailureID(rawValue: "UNKNOWN")
            }

            let finishEvent = DiagnosticEvent(
                occurredAt: clock.now,
                category: category,
                kind: .operationFinished(
                    OperationTrace(
                        operationID: operationID,
                        operation: operation,
                        outcome: .failed(failureID),
                        durationMilliseconds: durationMs,
                        attempt: attempt,
                        parentOperationID: parentOperationID
                    )
                ),
                severity: .error,
                operationID: operationID,
                metadata: [
                    DiagnosticMetadata(key: .operation, value: .string(operation.rawValue), privacy: .public),
                    DiagnosticMetadata(key: .durationMilliseconds, value: .durationMilliseconds(durationMs), privacy: .public),
                    DiagnosticMetadata(key: .failureID, value: .string(failureID.rawValue), privacy: .public)
                ]
            )
            await observability.record(finishEvent)
            throw error
        }
    }
}
