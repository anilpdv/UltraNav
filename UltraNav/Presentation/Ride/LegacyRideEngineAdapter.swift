import Foundation
import Combine

// TODO(PHASE-1N):
// Remove after views consume presentation models directly.

@MainActor
final class LegacyRideEngineAdapter: ObservableObject {
    @Published private(set) var snapshot: RideSnapshot

    private let engine: any RideEngineProviding
    private var task: Task<Void, Never>?

    init(engine: any RideEngineProviding) {
        self.engine = engine
        self.snapshot = engine.currentSnapshot

        task = Task { [weak self] in
            guard let self else { return }
            for await snapshot in engine.snapshots {
                guard !Task.isCancelled else { break }
                self.snapshot = snapshot
            }
        }
    }

    deinit {
        task?.cancel()
    }

    var isRiding: Bool {
        snapshot.state.hasActiveRideSession
    }

    var isPaused: Bool {
        snapshot.state == .paused
    }

    var currentSpeed: Double {
        snapshot.metrics.currentSpeedMetersPerSecond ?? 0
    }

    var heartRate: Int {
        snapshot.metrics.heartRateBeatsPerMinute ?? 0
    }

    var power: Int {
        snapshot.metrics.powerWatts ?? 0
    }

    var cadence: Double {
        snapshot.metrics.cadenceRevolutionsPerMinute ?? 0
    }

    var distance: Double {
        snapshot.metrics.distanceMeters
    }

    var elapsedTime: TimeInterval {
        snapshot.elapsedTimeSeconds
    }

    var movingTime: TimeInterval {
        snapshot.movingTimeSeconds
    }

    func prepare() {
        Task {
            await engine.send(.prepare)
        }
    }

    func startRide() {
        Task {
            await engine.send(.start)
        }
    }

    func pauseRide() {
        Task {
            await engine.send(.pause)
        }
    }

    func resumeRide() {
        Task {
            await engine.send(.resume)
        }
    }

    func finishRide() {
        Task {
            await engine.send(.finish)
        }
    }

    func reset() {
        Task {
            await engine.send(.reset)
        }
    }
}
