import Foundation

/// Protocol defining content selection algorithms for GPX documents.
public protocol GPXContentSelecting: Sendable {
    func selectContent(
        from document: GPXParsedDocument,
        policy: GPXContentSelectionPolicy
    ) throws -> GPXContentSelection

    func extractCandidates(
        from document: GPXParsedDocument
    ) -> [GPXContentCandidate]
}
