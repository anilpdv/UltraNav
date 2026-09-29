import Foundation

/// Report detailing the migration of stored route records.
public struct RouteStorageMigrationReport: Equatable, Sendable {
    public let migratedCount: Int
    public let failedCount: Int
    public let details: [String]

    public init(migratedCount: Int, failedCount: Int, details: [String] = []) {
        self.migratedCount = migratedCount
        self.failedCount = failedCount
        self.details = details
    }
}

/// Migrator that transforms legacy schema records into V2 records with fingerprints.
public struct RouteStorageMigrator: Sendable {
    private let identityCreator: any RouteIdentityCreating

    public init(identityCreator: any RouteIdentityCreating = SHA256RouteIdentityCreator()) {
        self.identityCreator = identityCreator
    }

    public func migrate(data: Data) throws -> RouteStorageRecord {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Try decoding as current V2 first
        if let v2 = try? decoder.decode(RouteStorageRecordV2.self, from: data) {
            return v2
        }

        // Try decoding as V1 and migrate to V2
        if let v1 = try? decoder.decode(RouteStorageRecordV1.self, from: data) {
            let fingerprints = identityCreator.makeFingerprints(
                points: v1.route.points,
                segments: v1.route.segments,
                waypoints: v1.route.waypoints,
                version: .version2
            )

            return RouteStorageRecordV2(
                schemaVersion: 2,
                normalizationVersion: .version2,
                route: v1.route,
                summary: v1.summary,
                fingerprints: fingerprints,
                storedAt: Date()
            )
        }

        throw RouteStoreError.readFailed("Unknown route storage schema version or corrupted data.")
    }
}
