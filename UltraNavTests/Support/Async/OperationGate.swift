import Foundation
@testable import UltraNav

/// Actor providing controlled suspension and release for testing asynchronous operations and races.
actor OperationGate {
    private var continuation: CheckedContinuation<Void, any Error>?
    private(set) var wasEntered = false
    private(set) var isWaiting = false
    private var hasResumed = false

    init() {}

    /// Waits until released by `succeed()` or `fail(_:)`.
    func wait() async throws {
        guard !hasResumed else { return }
        guard continuation == nil else {
            struct MultipleWaitersError: Error {}
            throw MultipleWaitersError()
        }

        wasEntered = true
        isWaiting = true

        try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
        }
    }

    /// Releases the waiting task with success.
    func succeed() {
        guard let cont = continuation else {
            hasResumed = true
            return
        }
        continuation = nil
        isWaiting = false
        hasResumed = true
        cont.resume()
    }

    /// Releases the waiting task with failure.
    func fail(_ error: any Error) {
        guard let cont = continuation else {
            hasResumed = true
            return
        }
        continuation = nil
        isWaiting = false
        hasResumed = true
        cont.resume(throwing: error)
    }

    /// Resets the gate for subsequent operations.
    func reset() {
        if let cont = continuation {
            continuation = nil
            isWaiting = false
            cont.resume()
        }
        wasEntered = false
        isWaiting = false
        hasResumed = false
    }
}
