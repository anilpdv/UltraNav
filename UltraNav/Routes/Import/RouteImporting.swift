import Foundation

/// Protocol defining the high-level import pipeline.
public protocol RouteImporting: Sendable {
    func importRoute(from source: RouteImportSource, policy: RouteImportPolicy) async throws -> RouteImportResult
}

public extension RouteImporting {
    func importRoute(from source: RouteImportSource) async throws -> RouteImportResult {
        try await importRoute(from: source, policy: .default)
    }
}
