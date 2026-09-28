import Foundation

enum WorkoutServiceEvent: Equatable, Sendable {
    case authorizationChanged(WorkoutAuthorizationStatus)
    case stateChanged(WorkoutServiceState)
    case heartRateReceived(beatsPerMinute: Int, timestamp: Date)
    case activeEnergyReceived(kilocalories: Double, timestamp: Date)
    case distanceReceived(meters: Double, timestamp: Date)
    case metricReceived(WorkoutMetric)
    case finalizationStarted
    case workoutSaved(CompletedWorkoutReference)
    case failed(WorkoutServiceFailure)
}
