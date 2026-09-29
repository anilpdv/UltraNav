import Foundation

struct DiagnosticSnapshot: Equatable, Sendable {
    let generatedAt: Date
    let applicationState: AppLifecycleState
    let subsystemHealth: [ObservedSubsystem: SubsystemHealth]
    let counters: [CounterMetric: Int]
    let gauges: [GaugeMetric: Double]
    let recentEvents: [DiagnosticEvent]
    let recentFailures: [FailureRecord]

    init(
        generatedAt: Date = Date(),
        applicationState: AppLifecycleState = .created,
        subsystemHealth: [ObservedSubsystem: SubsystemHealth] = [:],
        counters: [CounterMetric: Int] = [:],
        gauges: [GaugeMetric: Double] = [:],
        recentEvents: [DiagnosticEvent] = [],
        recentFailures: [FailureRecord] = []
    ) {
        self.generatedAt = generatedAt
        self.applicationState = applicationState
        self.subsystemHealth = subsystemHealth
        self.counters = counters
        self.gauges = gauges
        self.recentEvents = recentEvents
        self.recentFailures = recentFailures
    }
}
