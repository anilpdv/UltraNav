import Foundation
import Combine

@MainActor
final class DiagnosticsViewModel: ObservableObject {
    @Published private(set) var state: DiagnosticsViewState = .empty

    private let observability: any ObservabilityProviding
    private let clock: any ClockProviding

    init(
        observability: any ObservabilityProviding,
        clock: any ClockProviding = SystemClock()
    ) {
        self.observability = observability
        self.clock = clock
    }

    func refresh() async {
        let snapshot = await observability.snapshot()

        let healthRows = snapshot.subsystemHealth.values.sorted(by: { $0.subsystem.rawValue < $1.subsystem.rawValue }).map { h in
            SubsystemHealthRowViewState(
                name: h.subsystem.rawValue.capitalized,
                statusText: "\(h.status)".capitalized,
                isHealthy: h.status == .healthy,
                activeDegradationCount: h.activeDegradations.count
            )
        }

        let counterRows = snapshot.counters.sorted(by: { $0.key.rawValue < $1.key.rawValue }).map { k, v in
            CounterRowViewState(name: k.rawValue, count: v)
        }

        let gaugeRows = snapshot.gauges.sorted(by: { $0.key.rawValue < $1.key.rawValue }).map { k, v in
            GaugeRowViewState(name: k.rawValue, valueText: String(format: "%.2f", v))
        }

        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium

        self.state = DiagnosticsViewState(
            appStateText: snapshot.applicationState.rawValue.capitalized,
            lastUpdatedText: dateFormatter.string(from: snapshot.generatedAt),
            subsystemHealthList: healthRows,
            counterList: counterRows,
            gaugeList: gaugeRows,
            recentEventCount: snapshot.recentEvents.count,
            recentFailureCount: snapshot.recentFailures.count
        )
    }
}
