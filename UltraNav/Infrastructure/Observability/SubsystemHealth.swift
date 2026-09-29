import Foundation

enum SubsystemHealthStatus: Int, Comparable, Sendable {
    case unknown = 0
    case healthy = 1
    case degraded = 2
    case unavailable = 3
    case failed = 4

    static func < (lhs: SubsystemHealthStatus, rhs: SubsystemHealthStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct SubsystemHealth: Equatable, Sendable {
    let subsystem: ObservedSubsystem
    let status: SubsystemHealthStatus
    let updatedAt: Date
    let activeFailureID: FailureID?
    let activeDegradations: [FailureID]
    let message: String?

    init(
        subsystem: ObservedSubsystem,
        status: SubsystemHealthStatus,
        updatedAt: Date = Date(),
        activeFailureID: FailureID? = nil,
        activeDegradations: [FailureID] = [],
        message: String? = nil
    ) {
        self.subsystem = subsystem
        self.status = status
        self.updatedAt = updatedAt
        self.activeFailureID = activeFailureID
        self.activeDegradations = activeDegradations
        self.message = message
    }
}
