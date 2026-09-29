import Foundation
import Testing
@testable import UltraNav

@Suite("RecoveryPolicy Tests")
struct RecoveryPolicyTests {
    @Test("StandardRecoveryPolicy provides valid recommendations and retries")
    func testPolicyRecommendations() {
        let policy = StandardRecoveryPolicy()

        let sensorFailure: UltraNavFailure = .sensors(.disconnectedUnexpectedly(SensorIdentifier(rawValue: "power-1")))
        let sensorContext = FailureContext(operation: .sensorMeasurement, rideState: .active)
        let sensorRec = policy.recommendation(for: sensorFailure, context: sensorContext)

        #expect(sensorRec.recoverability == .retryable)
        #expect(sensorRec.actions.contains(.continueWithoutSensors))
        #expect(sensorRec.automaticRetry != nil)

        let fatalFailure: UltraNavFailure = .app(.dependencyConstructionFailed)
        let fatalContext = FailureContext(operation: .appStartup)
        let fatalRec = policy.recommendation(for: fatalFailure, context: fatalContext)

        #expect(fatalRec.recoverability == .fatalForApplication)
        #expect(fatalRec.automaticRetry == nil)
    }

    @Test("AutomaticRetryPolicy calculates exponential backoff correctly")
    func testExponentialBackoff() {
        let policy = AutomaticRetryPolicy(maximumAttempts: 3, initialDelaySeconds: 1.0, multiplier: 2.0, maximumDelaySeconds: 10.0)

        #expect(policy.delay(forAttempt: 0) == 1.0)
        #expect(policy.delay(forAttempt: 1) == 2.0)
        #expect(policy.delay(forAttempt: 2) == 4.0)
        #expect(policy.delay(forAttempt: 3) == nil) // Exceeded maximum attempts
    }
}
