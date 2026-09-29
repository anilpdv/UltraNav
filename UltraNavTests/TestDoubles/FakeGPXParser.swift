import Foundation
@testable import UltraNav

final class FakeGPXParser: GPXParsing, @unchecked Sendable {
    var resultDocument: GPXParsedDocument?
    var errorToThrow: Error?
    private(set) var parseCallCount = 0

    init(resultDocument: GPXParsedDocument? = nil, errorToThrow: Error? = nil) {
        self.resultDocument = resultDocument
        self.errorToThrow = errorToThrow
    }

    func parse(data: Data) async throws -> GPXParsedDocument {
        parseCallCount += 1
        if let error = errorToThrow {
            throw error
        }
        if let doc = resultDocument {
            return doc
        }
        return GPXParsedDocument()
    }
}
