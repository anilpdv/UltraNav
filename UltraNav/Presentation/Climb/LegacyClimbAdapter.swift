import Foundation
import Observation

/// Observable presentation adapter bridging ClimbEngine snapshot stream to SwiftUI views.
@Observable
@MainActor
final class LegacyClimbAdapter {
    private let climbEngine: ClimbEngineProviding
    private var streamTask: Task<Void, Never>?

    private(set) var snapshot: ClimbSnapshot

    var activeClimb: Climb? {
        snapshot.activeClimb
    }

    var activeClimbProgress: ClimbProgress? {
        snapshot.activeClimbProgress
    }

    var distanceRemainingInClimb: Double {
        snapshot.distanceRemainingInActiveClimb ?? 0
    }

    var currentElevationMeters: Double? {
        snapshot.currentElevationMeters
    }

    var elevationGainedMeters: Double {
        snapshot.totalElevationGainMeters
    }

    var currentGradePercent: Double {
        snapshot.currentGradePercent
    }

    var vamMetersPerHour: Double {
        snapshot.vamMetersPerHour
    }

    var upcomingClimb: Climb? {
        snapshot.upcomingClimb
    }

    var distanceToUpcomingClimbMeters: Double? {
        snapshot.distanceToUpcomingClimbMeters
    }

    var hasActiveClimb: Bool {
        snapshot.hasActiveClimb
    }

    init(climbEngine: ClimbEngineProviding) {
        self.climbEngine = climbEngine
        self.snapshot = climbEngine.currentSnapshot
        self.streamTask = Task { [weak self] in
            for await snap in climbEngine.snapshots {
                guard let self else { return }
                self.snapshot = snap
            }
        }
    }
}
