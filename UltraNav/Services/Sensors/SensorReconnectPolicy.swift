import Foundation

/// Defines reasons for sensor disconnection.
enum SensorDisconnectReason: Equatable, Sendable {
    case manualUserRequest
    case linkLoss
    case timeout
    case bluetoothPoweredOff
    case protocolError
    case unknown
}

/// Readiness state of a discovered and connected sensor.
enum SensorReadiness: Equatable, Sendable {
    case discovered
    case connecting
    case connected
    case discoveringServices
    case discoveringCharacteristics
    case enablingNotifications
    case ready
    case disconnected(reason: SensorDisconnectReason)
}

/// Policy governing retry timing and limits for reconnecting unexpectedly dropped sensors.
struct SensorReconnectPolicy: Equatable, Sendable {
    var maxRetryAttempts: Int
    var initialBackoffSeconds: TimeInterval
    var backoffMultiplier: Double
    var maxBackoffSeconds: TimeInterval
    var allowAutoReconnectOnManualDisconnect: Bool

    static let standard = SensorReconnectPolicy(
        maxRetryAttempts: 5,
        initialBackoffSeconds: 1.0,
        backoffMultiplier: 2.0,
        maxBackoffSeconds: 16.0,
        allowAutoReconnectOnManualDisconnect: false
    )

    init(
        maxRetryAttempts: Int = 5,
        initialBackoffSeconds: TimeInterval = 1.0,
        backoffMultiplier: Double = 2.0,
        maxBackoffSeconds: TimeInterval = 16.0,
        allowAutoReconnectOnManualDisconnect: Bool = false
    ) {
        self.maxRetryAttempts = maxRetryAttempts
        self.initialBackoffSeconds = initialBackoffSeconds
        self.backoffMultiplier = backoffMultiplier
        self.maxBackoffSeconds = maxBackoffSeconds
        self.allowAutoReconnectOnManualDisconnect = allowAutoReconnectOnManualDisconnect
    }

    func delayForAttempt(_ attempt: Int) -> TimeInterval? {
        guard attempt > 0 && attempt <= maxRetryAttempts else {
            return nil
        }
        let delay = initialBackoffSeconds * pow(backoffMultiplier, Double(attempt - 1))
        return min(maxBackoffSeconds, delay)
    }

    func shouldReconnect(after reason: SensorDisconnectReason, currentAttempt: Int) -> Bool {
        switch reason {
        case .manualUserRequest:
            return allowAutoReconnectOnManualDisconnect
        case .bluetoothPoweredOff:
            return false
        case .linkLoss, .timeout, .protocolError, .unknown:
            return currentAttempt < maxRetryAttempts
        }
    }
}
