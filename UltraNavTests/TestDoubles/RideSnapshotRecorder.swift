import Foundation
@testable import UltraNav

@MainActor
final class RideSnapshotRecorder {
    private(set) var recordedSnapshots: [RideSnapshot] = []
    private var task: Task<Void, Never>?

    func startRecording(from engine: any RideEngineProviding) {
        recordedSnapshots.append(engine.currentSnapshot)
        task = Task { [weak self] in
            for await snapshot in engine.snapshots {
                guard !Task.isCancelled else { break }
                self?.recordedSnapshots.append(snapshot)
            }
        }
    }

    func stopRecording() {
        task?.cancel()
        task = nil
    }
}
