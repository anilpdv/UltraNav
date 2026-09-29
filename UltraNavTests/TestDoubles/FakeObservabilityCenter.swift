import Foundation
@testable import UltraNav

actor FakeObservabilityCenter: ObservabilityProviding {
    private(set) var recordedEvents: [DiagnosticEvent] = []
    private(set) var counters: [CounterMetric: Int] = [:]
    private(set) var gauges: [GaugeMetric: Double] = [:]
    private(set) var subsystemHealth: [ObservedSubsystem: SubsystemHealth] = [:]

    private let clock: any ClockProviding

    init(clock: any ClockProviding = SystemClock()) {
        self.clock = clock
    }

    func record(_ event: DiagnosticEvent) async {
        recordedEvents.append(event)
    }

    func increment(_ counter: CounterMetric, by amount: Int) async {
        let current = counters[counter, default: 0]
        counters[counter] = current + amount
    }

    func setGauge(_ gauge: GaugeMetric, value: Double) async {
        gauges[gauge] = value
    }

    func updateHealth(_ health: SubsystemHealth) async {
        subsystemHealth[health.subsystem] = health
    }

    func snapshot() async -> DiagnosticSnapshot {
        DiagnosticSnapshot(
            generatedAt: clock.now,
            applicationState: .running,
            subsystemHealth: subsystemHealth,
            counters: counters,
            gauges: gauges,
            recentEvents: recordedEvents,
            recentFailures: []
        )
    }

    func clear() {
        recordedEvents.removeAll()
        counters.removeAll()
        gauges.removeAll()
        subsystemHealth.removeAll()
    }
}
