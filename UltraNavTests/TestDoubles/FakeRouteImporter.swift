import Foundation
@testable import UltraNav

final class FakeRouteImporter: RouteImporting, @unchecked Sendable {
    private let lock = NSLock()
    var resultToReturn: RouteImportResult?
    var errorToThrow: (any Error)?
    var importGate: OperationGate?
    private(set) var importCallCount = 0

    init(resultToReturn: RouteImportResult? = nil, errorToThrow: (any Error)? = nil) {
        self.resultToReturn = resultToReturn
        self.errorToThrow = errorToThrow
    }

    func importRoute(from source: RouteImportSource, policy: RouteImportPolicy) async throws -> RouteImportResult {
        lock.withLock {
            importCallCount += 1
        }

        if let gate = importGate {
            try await gate.wait()
        }

        if let error = errorToThrow {
            throw error
        }
        if let result = resultToReturn {
            return result
        }

        let route = RouteFixture.straightRoute(id: RouteID(sha256Hex: "fakeimport"), name: "Imported Fake Route")
        return RouteImportResult(route: route, warnings: [])
    }
}
