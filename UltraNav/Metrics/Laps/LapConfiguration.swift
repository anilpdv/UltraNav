import Foundation

enum LapTrigger: Equatable, Codable, Sendable {
    case manual
    case distance(meters: Double)
    case time(seconds: TimeInterval)
    case routePoint(String)
}

enum AutomaticLapPolicy: Equatable, Sendable {
    case disabled
    case distance(meters: Double)
    case time(seconds: TimeInterval)
}

struct LapConfiguration: Equatable, Sendable {
    let automaticPolicy: AutomaticLapPolicy
    let minimumLapDurationSeconds: TimeInterval
    let minimumLapDistanceMeters: Double

    static let standard = LapConfiguration(
        automaticPolicy: .disabled,
        minimumLapDurationSeconds: 5.0,
        minimumLapDistanceMeters: 10.0
    )
}
