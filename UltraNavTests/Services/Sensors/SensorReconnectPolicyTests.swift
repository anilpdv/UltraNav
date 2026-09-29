import XCTest
@testable import UltraNav

final class SensorReconnectPolicyTests: XCTestCase {
    private var policy: SensorReconnectPolicy!

    override func setUp() {
        super.setUp()
        policy = SensorReconnectPolicy(
            maxRetryAttempts: 4,
            initialBackoffSeconds: 1.0,
            backoffMultiplier: 2.0,
            maxBackoffSeconds: 10.0,
            allowAutoReconnectOnManualDisconnect: false
        )
    }

    func test_delayForAttempt_exponentialBackoff() {
        XCTAssertEqual(policy.delayForAttempt(1), 1.0)
        XCTAssertEqual(policy.delayForAttempt(2), 2.0)
        XCTAssertEqual(policy.delayForAttempt(3), 4.0)
        XCTAssertEqual(policy.delayForAttempt(4), 8.0)
        XCTAssertNil(policy.delayForAttempt(5))
    }

    func test_manualDisconnect_doesNotReconnectByDefault() {
        XCTAssertFalse(policy.shouldReconnect(after: .manualUserRequest, currentAttempt: 0))
    }

    func test_linkLoss_allowsReconnectUpToMaxAttempts() {
        XCTAssertTrue(policy.shouldReconnect(after: .linkLoss, currentAttempt: 0))
        XCTAssertTrue(policy.shouldReconnect(after: .linkLoss, currentAttempt: 3))
        XCTAssertFalse(policy.shouldReconnect(after: .linkLoss, currentAttempt: 4))
    }
}
