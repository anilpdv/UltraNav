import Foundation

enum ObservedOperation: String, CaseIterable, Equatable, Hashable, Sendable {
    case appStartup

    case ridePreparation
    case rideStart
    case ridePause
    case rideResume
    case rideFinish

    case routeRead
    case gpxParse
    case routeNormalize
    case routeSave
    case routeLoad

    case navigationMatch
    case cueGeneration
    case climbAnalysis

    case sensorScan
    case sensorConnect
    case workoutFinalization
}
