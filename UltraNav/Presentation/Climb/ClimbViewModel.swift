import Foundation
import Observation

@Observable
@MainActor
public final class ClimbViewModel {
    public private(set) var state: ClimbViewState
    private let climbEngine: any ClimbEngineProviding
    private let mapper: ClimbViewStateMapper
    private var preferences: UnitPreferences

    private var snapshotTask: Task<Void, Never>?

    init(
        climbEngine: any ClimbEngineProviding,
        mapper: ClimbViewStateMapper = ClimbViewStateMapper(),
        preferences: UnitPreferences = .default
    ) {
        self.climbEngine = climbEngine
        self.mapper = mapper
        self.preferences = preferences
        self.state = mapper.map(
            snapshot: climbEngine.currentSnapshot,
            preferences: preferences
        )

        startSnapshotConsumer()
    }

    public func handle(_ action: ClimbPresentationAction) {
        switch action {
        case .appeared:
            updateState()
        case .retrySelected:
            break
        }
    }

    public func updatePreferences(_ newPreferences: UnitPreferences) {
        self.preferences = newPreferences
        updateState()
    }

    private func startSnapshotConsumer() {
        let snapshots = climbEngine.snapshots
        snapshotTask = Task { [weak self] in
            for await snapshot in snapshots {
                guard let self, !Task.isCancelled else { break }
                self.state = self.mapper.map(
                    snapshot: snapshot,
                    preferences: self.preferences
                )
            }
        }
    }

    private func updateState() {
        state = mapper.map(
            snapshot: climbEngine.currentSnapshot,
            preferences: preferences
        )
    }
}
