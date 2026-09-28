import Foundation
import HealthKit
@testable import UltraNav

actor FakeHealthStore: HealthKitAuthorizing {
    var available: Bool = true
    var stubbedRequestStatus: HKAuthorizationRequestStatus = .unnecessary
    var shouldFailRequest: Bool = false

    func isHealthDataAvailable() async -> Bool {
        available
    }

    func setAvailable(_ val: Bool) {
        self.available = val
    }

    func setStubbedRequestStatus(_ val: HKAuthorizationRequestStatus) {
        self.stubbedRequestStatus = val
    }

    func setShouldFailRequest(_ val: Bool) {
        self.shouldFailRequest = val
    }

    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws {
        if !available {
            throw WorkoutServiceFailure.healthDataUnavailable
        }
        if shouldFailRequest {
            throw WorkoutServiceFailure.authorizationFailed
        }
    }

    func authorizationRequestStatus(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws -> HKAuthorizationRequestStatus {
        if !available {
            return .unknown
        }
        return stubbedRequestStatus
    }
}
