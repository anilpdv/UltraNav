import Foundation
import HealthKit

protocol HealthKitAuthorizing: Sendable {
    func isHealthDataAvailable() async -> Bool

    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws

    func authorizationRequestStatus(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws -> HKAuthorizationRequestStatus
}

actor HealthKitAuthorizationClient: HealthKitAuthorizing {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func isHealthDataAvailable() async -> Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws {
        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }

    func authorizationRequestStatus(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws -> HKAuthorizationRequestStatus {
        try await healthStore.statusForAuthorizationRequest(toShare: typesToShare, read: typesToRead)
    }
}
