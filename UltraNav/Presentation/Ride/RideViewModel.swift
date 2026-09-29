import Foundation
import Observation

@Observable
@MainActor
public final class RideViewModel {
    public private(set) var state: RideViewState
    private let rideEngine: any RideEngineProviding
    private let lifecycleCoordinator: RideLifecycleCoordinator
    private let mapper: RideViewStateMapper

    private var snapshotTask: Task<Void, Never>?
    private var isShowingFinishConfirmation = false

    init(
        rideEngine: any RideEngineProviding,
        lifecycleCoordinator: RideLifecycleCoordinator,
        mapper: RideViewStateMapper = RideViewStateMapper()
    ) {
        self.rideEngine = rideEngine
        self.lifecycleCoordinator = lifecycleCoordinator
        self.mapper = mapper
        self.state = mapper.map(snapshot: rideEngine.currentSnapshot)

        startSnapshotConsumer()
    }

    public func handle(_ action: RidePresentationAction) {
        Task {
            switch action {
            case .appeared:
                updateState()
            case .primaryControlSelected:
                await handlePrimaryAction()
            case .secondaryControlSelected:
                await handleSecondaryAction()
            case .finishConfirmed:
                isShowingFinishConfirmation = false
                await lifecycleCoordinator.finish()
            case .finishCancelled:
                isShowingFinishConfirmation = false
                updateState()
            case .retrySelected:
                await lifecycleCoordinator.prepare()
            case .resetSelected:
                await lifecycleCoordinator.reset()
            }
        }
    }

    private func handlePrimaryAction() async {
        guard let action = state.controls.primaryAction else { return }
        switch action {
        case .prepare:
            await lifecycleCoordinator.prepare()
        case .start:
            await lifecycleCoordinator.start()
        case .pause:
            await lifecycleCoordinator.pause()
        case .resume:
            await lifecycleCoordinator.resume()
        case .finish:
            isShowingFinishConfirmation = true
            updateState()
        case .retry:
            await lifecycleCoordinator.prepare()
        case .reset:
            await lifecycleCoordinator.reset()
        }
    }

    private func handleSecondaryAction() async {
        guard let action = state.controls.secondaryAction else { return }
        switch action {
        case .finish:
            isShowingFinishConfirmation = true
            updateState()
        case .reset:
            await lifecycleCoordinator.reset()
        default:
            break
        }
    }

    private func startSnapshotConsumer() {
        let snapshots = rideEngine.snapshots
        snapshotTask = Task { [weak self] in
            for await snapshot in snapshots {
                guard let self, !Task.isCancelled else { break }
                self.state = self.mapper.map(
                    snapshot: snapshot,
                    showsFinishConfirmation: self.isShowingFinishConfirmation
                )
            }
        }
    }

    private func updateState() {
        state = mapper.map(
            snapshot: rideEngine.currentSnapshot,
            showsFinishConfirmation: isShowingFinishConfirmation
        )
    }
}
