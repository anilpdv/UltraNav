import Foundation
import CoreLocation

struct CachedDestination: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let locality: String?
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees

    init(
        id: UUID = UUID(),
        name: String,
        locality: String?,
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees
    ) {
        self.id = id
        self.name = name
        self.locality = locality
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct CachedSearchResults: Codable, Equatable, Sendable {
    let query: String
    let destinations: [CachedDestination]
    let savedAt: Date

    func isStale(
        at date: Date = .now,
        maximumAge: TimeInterval
    ) -> Bool {
        date.timeIntervalSince(savedAt) > maximumAge
    }
}

struct PendingMutation: Codable, Identifiable, Equatable, Sendable {
    enum Kind: String, Codable, Sendable {
        case saveDestination
        case removeDestination
    }

    let id: UUID
    let kind: Kind
    let destination: CachedDestination
    let createdAt: Date
    var retryCount: Int

    init(
        id: UUID = UUID(),
        kind: Kind,
        destination: CachedDestination,
        createdAt: Date = .now,
        retryCount: Int = 0
    ) {
        self.id = id
        self.kind = kind
        self.destination = destination
        self.createdAt = createdAt
        self.retryCount = retryCount
    }
}

actor AppCache {
    static let shared = AppCache()

    private let fileManager: FileManager
    private let cacheURL: URL
    private let pendingMutationsURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        fileManager: FileManager = .default,
        cacheURL: URL? = nil,
        pendingMutationsURL: URL? = nil
    ) {
        self.fileManager = fileManager

        let directory = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory

        let appDirectory = directory.appendingPathComponent(
            "UltraNav",
            isDirectory: true
        )
        self.cacheURL = cacheURL
            ?? appDirectory.appendingPathComponent("search-results.json")
        self.pendingMutationsURL = pendingMutationsURL
            ?? appDirectory.appendingPathComponent("pending-mutations.json")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func saveSearchResults(_ results: CachedSearchResults) throws {
        do {
            try write(results, to: cacheURL)
            AppLogger.persistence.info("Saved cached search results")
        } catch {
            AppLogger.persistence.error("Failed to save cached search results: \(String(describing: type(of: error)), privacy: .public)")
            throw error
        }
    }

    func loadSearchResults() throws -> CachedSearchResults? {
        do {
            let results = try load(CachedSearchResults.self, from: cacheURL)
            AppLogger.persistence.info("Loaded cached search results; cache present: \(results != nil, privacy: .public)")
            return results
        } catch {
            AppLogger.persistence.error("Failed to load cached search results: \(String(describing: type(of: error)), privacy: .public)")
            throw error
        }
    }

    func enqueueMutation(_ mutation: PendingMutation) throws {
        var mutations = (try loadPendingMutations()) ?? []

        // Collapse superseded mutations for the same destination so reconnect
        // applies only the user's latest intent.
        mutations.removeAll { $0.destination.id == mutation.destination.id }
        mutations.append(mutation)
        try write(mutations, to: pendingMutationsURL)
        AppLogger.persistence.info("Queued offline mutation; pending count: \(mutations.count, privacy: .public)")
    }

    func loadPendingMutations() throws -> [PendingMutation]? {
        try load([PendingMutation].self, from: pendingMutationsURL)
    }

    func replacePendingMutations(_ mutations: [PendingMutation]) throws {
        guard !mutations.isEmpty else {
            try removeIfPresent(pendingMutationsURL)
            return
        }
        try write(mutations, to: pendingMutationsURL)
    }

    func clear() throws {
        try removeIfPresent(cacheURL)
        try removeIfPresent(pendingMutationsURL)
        AppLogger.persistence.info("Cleared local cache")
    }

    private func write<Value: Encodable>(
        _ value: Value,
        to url: URL
    ) throws {
        try fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic)
    }

    private func load<Value: Decodable>(
        _ valueType: Value.Type,
        from url: URL
    ) throws -> Value? {
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(valueType, from: data)
        } catch {
            AppLogger.persistence.error("Discarding unreadable cache data: \(String(describing: Swift.type(of: error)), privacy: .public)")
            try? fileManager.removeItem(at: url)
            throw error
        }
    }

    private func removeIfPresent(_ url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }
        try fileManager.removeItem(at: url)
    }
}