import Foundation

protocol ObservabilityProviding: Sendable {
    func record(_ event: DiagnosticEvent) async
    func increment(_ counter: CounterMetric, by amount: Int) async
    func setGauge(_ gauge: GaugeMetric, value: Double) async
    func updateHealth(_ health: SubsystemHealth) async
    func snapshot() async -> DiagnosticSnapshot
}

extension ObservabilityProviding {
    func increment(_ counter: CounterMetric) async {
        await increment(counter, by: 1)
    }
}
