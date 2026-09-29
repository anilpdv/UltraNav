import Foundation

actor ObservabilityCenter: ObservabilityProviding {
    private let clock: any ClockProviding
    private let logger: any Logging
    private let failureRecorder: (any FailureRecording)?
    private let maximumEvents: Int

    private var nextSequence: UInt64 = 0
    private var events: [DiagnosticEvent] = []
    private var counters: [CounterMetric: Int] = [:]
    private var gauges: [GaugeMetric: Double] = [:]
    private var health: [ObservedSubsystem: SubsystemHealth] = [:]
    private var applicationState: AppLifecycleState = .created

    init(
        clock: any ClockProviding = SystemClock(),
        logger: any Logging = NoOpLogger(),
        failureRecorder: (any FailureRecording)? = nil,
        maximumEvents: Int = 250
    ) {
        self.clock = clock
        self.logger = logger
        self.failureRecorder = failureRecorder
        self.maximumEvents = max(1, maximumEvents)
    }

    func setApplicationState(_ state: AppLifecycleState) {
        self.applicationState = state
    }

    func record(_ event: DiagnosticEvent) async {
        nextSequence &+= 1
        let finalizedEvent: DiagnosticEvent
        if event.sequence == 0 {
            finalizedEvent = DiagnosticEvent(
                id: event.id,
                sequence: nextSequence,
                occurredAt: event.occurredAt,
                category: event.category,
                kind: event.kind,
                severity: event.severity,
                operationID: event.operationID,
                metadata: event.metadata
            )
        } else {
            finalizedEvent = event
        }

        events.append(finalizedEvent)
        if events.count > maximumEvents {
            events.removeFirst(events.count - maximumEvents)
        }

        let metadataEntries = finalizedEvent.metadata.map { meta in
            let logVal: LogMetadataValue
            switch meta.value {
            case .string(let s): logVal = .string(s)
            case .integer(let i): logVal = .integer(i)
            case .double(let d): logVal = .double(d)
            case .boolean(let b): logVal = .boolean(b)
            case .durationMilliseconds(let ms): logVal = .durationMilliseconds(ms)
            case .identifier(let id): logVal = .identifier(id)
            }
            return LogMetadataEntry(key: meta.key.rawValue, value: logVal, privacy: meta.privacy)
        }

        await logger.log(
            level: finalizedEvent.severity,
            category: finalizedEvent.category,
            message: logMessage(for: finalizedEvent),
            metadata: metadataEntries
        )
    }

    func increment(_ counter: CounterMetric, by amount: Int) async {
        let current = counters[counter, default: 0]
        counters[counter] = current + amount
    }

    func setGauge(_ gauge: GaugeMetric, value: Double) async {
        gauges[gauge] = value
    }

    func updateHealth(_ newHealth: SubsystemHealth) async {
        let previous = health[newHealth.subsystem]
        if let previous = previous, previous == newHealth {
            return
        }

        health[newHealth.subsystem] = newHealth

        let eventKind = DiagnosticEventKind.subsystemHealthChanged(newHealth)
        let severity: LogLevel
        switch newHealth.status {
        case .unknown, .healthy:
            severity = .information
        case .degraded:
            severity = .warning
        case .unavailable:
            severity = .notice
        case .failed:
            severity = .error
        }

        let category = logCategory(for: newHealth.subsystem)
        let event = DiagnosticEvent(
            occurredAt: newHealth.updatedAt,
            category: category,
            kind: eventKind,
            severity: severity,
            operationID: nil,
            metadata: [
                DiagnosticMetadata(key: .subsystem, value: .string(newHealth.subsystem.rawValue), privacy: .public),
                DiagnosticMetadata(key: .state, value: .string("\(newHealth.status)"), privacy: .public)
            ]
        )

        await record(event)
    }

    func snapshot() async -> DiagnosticSnapshot {
        let failures: [FailureRecord]
        if let recorder = failureRecorder {
            failures = await recorder.recentFailures(limit: 50)
        } else {
            failures = []
        }

        return DiagnosticSnapshot(
            generatedAt: clock.now,
            applicationState: applicationState,
            subsystemHealth: health,
            counters: counters,
            gauges: gauges,
            recentEvents: events,
            recentFailures: failures
        )
    }

    private func logCategory(for subsystem: ObservedSubsystem) -> LogCategory {
        switch subsystem {
        case .app: return .app
        case .ride: return .ride
        case .location: return .location
        case .workout: return .workout
        case .sensors: return .bluetooth
        case .routeLibrary: return .routeStore
        case .navigation: return .navigation
        case .metrics: return .metrics
        case .climb: return .climb
        case .presentation: return .presentation
        }
    }

    private func logMessage(for event: DiagnosticEvent) -> String {
        switch event.kind {
        case .stateTransition(let trace):
            return "State transition in \(trace.subsystem.rawValue): \(trace.fromState) -> \(trace.toState) [event: \(trace.event)]"
        case .operationStarted(let trace):
            return "Operation started: \(trace.operation.rawValue)"
        case .operationFinished(let trace):
            let outcomeDesc: String
            switch trace.outcome {
            case .succeeded: outcomeDesc = "succeeded"
            case .failed(let id): outcomeDesc = "failed (\(id.rawValue))"
            case .cancelled: outcomeDesc = "cancelled"
            case .superseded: outcomeDesc = "superseded"
            case .degraded: outcomeDesc = "degraded"
            case .none: outcomeDesc = "completed"
            }
            let durationDesc = trace.durationMilliseconds.map { String(format: " in %.2fms", $0) } ?? ""
            return "Operation \(trace.operation.rawValue) \(outcomeDesc)\(durationDesc)"
        case .failureRecorded(let id):
            return "Failure recorded: \(id.rawValue)"
        case .degradationEntered(let id):
            return "Degradation entered: \(id.rawValue)"
        case .degradationResolved(let id):
            return "Degradation resolved: \(id.rawValue)"
        case .eventDropped(let drop):
            return "Event dropped on stream \(drop.stream.rawValue): \(drop.droppedCount) items (capacity: \(drop.bufferCapacity))"
        case .inputDiscarded(let discard):
            return "Input discarded in \(discard.subsystem.rawValue): \(discard.reason.rawValue) (count: \(discard.count))"
        case .subsystemHealthChanged(let h):
            return "Subsystem health changed for \(h.subsystem.rawValue): \(h.status)"
        case .custom(let msg):
            return msg
        }
    }
}
