import Foundation

struct FailureDeduplicationKey: Hashable, Sendable {
    let failureID: FailureID
    let sensorID: SensorIdentifier?
    let routeID: Route.ID?
    let operation: FailureOperation

    init(
        failureID: FailureID,
        sensorID: SensorIdentifier? = nil,
        routeID: Route.ID? = nil,
        operation: FailureOperation
    ) {
        self.failureID = failureID
        self.sensorID = sensorID
        self.routeID = routeID
        self.operation = operation
    }

    init(record: FailureRecord) {
        self.failureID = record.failureID
        self.sensorID = record.context.sensorID
        self.routeID = record.context.routeID
        self.operation = record.context.operation
    }
}

struct FailureSuppressionPolicy: Equatable, Sendable {
    let informationalSeconds: TimeInterval
    let warningSeconds: TimeInterval
    let highSeconds: TimeInterval

    init(
        informationalSeconds: TimeInterval = 60,
        warningSeconds: TimeInterval = 30,
        highSeconds: TimeInterval = 10
    ) {
        self.informationalSeconds = informationalSeconds
        self.warningSeconds = warningSeconds
        self.highSeconds = highSeconds
    }

    func suppressionInterval(for severity: FailureSeverity) -> TimeInterval {
        switch severity {
        case .informational:
            return informationalSeconds
        case .warning:
            return warningSeconds
        case .high:
            return highSeconds
        case .critical:
            return 0
        }
    }

    static let standard = FailureSuppressionPolicy(
        informationalSeconds: 60,
        warningSeconds: 30,
        highSeconds: 10
    )
}
