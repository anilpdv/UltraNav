import Foundation
import HealthKit

struct WorkoutConfiguration: Equatable, Sendable {
    enum LocationMode: Equatable, Sendable {
        case outdoor
        case indoor
    }

    enum Activity: Equatable, Sendable {
        case cycling
    }

    let activity: Activity
    let locationMode: LocationMode

    static let outdoorCycling = WorkoutConfiguration(
        activity: .cycling,
        locationMode: .outdoor
    )

    func makeHealthKitConfiguration() -> HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()
        switch activity {
        case .cycling:
            configuration.activityType = .cycling
        }
        switch locationMode {
        case .outdoor:
            configuration.locationType = .outdoor
        case .indoor:
            configuration.locationType = .indoor
        }
        return configuration
    }
}
