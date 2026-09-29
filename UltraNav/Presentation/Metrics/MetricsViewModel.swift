import Foundation
import Observation

@Observable
@MainActor
public final class MetricsViewModel {
    public private(set) var state: MetricsViewState
    private let metricsEngine: any MetricsEngineProviding
    private let rideEngine: any RideEngineProviding
    private let mapper: MetricsViewStateMapper
    private var preferences: UnitPreferences

    private var metricsTask: Task<Void, Never>?
    private var rideTask: Task<Void, Never>?

    init(
        metricsEngine: any MetricsEngineProviding,
        rideEngine: any RideEngineProviding,
        mapper: MetricsViewStateMapper = MetricsViewStateMapper(),
        preferences: UnitPreferences = .default
    ) {
        self.metricsEngine = metricsEngine
        self.rideEngine = rideEngine
        self.mapper = mapper
        self.preferences = preferences
        self.state = mapper.map(
            metrics: metricsEngine.currentSnapshot,
            ride: rideEngine.currentSnapshot,
            preferences: preferences
        )

        startConsumers()
    }

    public func handle(_ action: MetricsPresentationAction) {
        switch action {
        case .appeared:
            updateState()
        case .tileSelected:
            break
        }
    }

    public func updatePreferences(_ newPreferences: UnitPreferences) {
        self.preferences = newPreferences
        updateState()
    }

    private func startConsumers() {
        let metricSnapshots = metricsEngine.snapshots
        metricsTask = Task { [weak self] in
            for await _ in metricSnapshots {
                guard let self, !Task.isCancelled else { break }
                self.updateState()
            }
        }

        let rideSnapshots = rideEngine.snapshots
        rideTask = Task { [weak self] in
            for await _ in rideSnapshots {
                guard let self, !Task.isCancelled else { break }
                self.updateState()
            }
        }
    }

    private func updateState() {
        state = mapper.map(
            metrics: metricsEngine.currentSnapshot,
            ride: rideEngine.currentSnapshot,
            preferences: preferences
        )
    }
}
