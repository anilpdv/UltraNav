import Foundation
import OSLog

/// Actor owning file persistence, indexing, and transactional isolation for all stored routes.
public actor RouteStore: RouteStoring {
    private let storageDirectory: URL
    private let fileSystem: any RouteFileSystemProviding
    private let codec: any RouteStorageCodec
    private let logger = Logger(subsystem: "com.ultranav.routes", category: "RouteStore")

    private var cachedIndex: RouteStoreIndex?

    private var indexFileURL: URL {
        storageDirectory.appendingPathComponent("index-v1.json")
    }

    public init(
        storageDirectory: URL? = nil,
        fileSystem: any RouteFileSystemProviding = StandardRouteFileSystem(),
        codec: any RouteStorageCodec = JSONRouteStorageCodec()
    ) {
        if let dir = storageDirectory {
            self.storageDirectory = dir
        } else {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            self.storageDirectory = docs.appendingPathComponent("Routes", isDirectory: true)
        }
        self.fileSystem = fileSystem
        self.codec = codec

        try? self.fileSystem.createDirectory(at: self.storageDirectory)
    }

    // MARK: - RouteStoring Protocol

    public func listRoutes() async throws -> [RouteSummary] {
        let index = try await getOrLoadIndex()
        return index.summaries.sorted { $0.importedAt > $1.importedAt }
    }

    public func loadRoute(id: Route.ID) async throws -> Route {
        let fileURL = recordFileURL(for: id)
        guard fileSystem.fileExists(at: fileURL) else {
            throw RouteStoreError.routeNotFound(id)
        }

        do {
            let data = try fileSystem.readData(from: fileURL)
            let record = try codec.decodeRecord(from: data)
            return record.route
        } catch let err as RouteStoreError {
            throw err
        } catch {
            throw RouteStoreError.readFailed("Failed to load route \(id.rawValue): \(error.localizedDescription)")
        }
    }

    public func saveRoute(
        _ route: Route,
        behavior: RouteSaveBehavior = .overwriteExisting
    ) async throws -> RouteSaveOutcome {
        let exists = await routeExists(id: route.id)
        if exists && behavior == .failIfExists {
            throw RouteStoreError.duplicateRoute(route.id)
        }

        let summary = RouteSummary(from: route)
        let record = RouteStorageRecord(route: route, summary: summary)

        do {
            let recordData = try codec.encodeRecord(record)
            let fileURL = recordFileURL(for: route.id)
            try fileSystem.writeData(recordData, to: fileURL, atomically: true)
        } catch {
            throw RouteStoreError.writeFailed("Failed to write record for \(route.id.rawValue): \(error.localizedDescription)")
        }

        // Update Index
        var index = try await getOrLoadIndex()
        if let existingIdx = index.summaries.firstIndex(where: { $0.id == route.id }) {
            index.summaries[existingIdx] = summary
        } else {
            index.summaries.append(summary)
        }
        index.lastUpdated = Date()

        try await persistIndex(index)
        self.cachedIndex = index

        return exists ? .overwritten : .savedNew
    }

    public func deleteRoute(
        id: Route.ID,
        activeRouteID: Route.ID? = nil
    ) async throws {
        if let active = activeRouteID, active == id {
            throw RouteStoreError.activeRouteProtected(id)
        }

        let fileURL = recordFileURL(for: id)
        guard fileSystem.fileExists(at: fileURL) else {
            throw RouteStoreError.routeNotFound(id)
        }

        do {
            try fileSystem.removeItem(at: fileURL)
        } catch {
            throw RouteStoreError.deleteFailed("Failed to delete record for \(id.rawValue): \(error.localizedDescription)")
        }

        // Update index
        var index = try await getOrLoadIndex()
        index.summaries.removeAll { $0.id == id }
        index.lastUpdated = Date()

        try await persistIndex(index)
        self.cachedIndex = index
    }

    public func routeExists(id: Route.ID) async -> Bool {
        let fileURL = recordFileURL(for: id)
        return fileSystem.fileExists(at: fileURL)
    }

    // MARK: - Internal Index & Recovery Helpers

    private func getOrLoadIndex() async throws -> RouteStoreIndex {
        if let cached = cachedIndex {
            return cached
        }

        if fileSystem.fileExists(at: indexFileURL) {
            do {
                let data = try fileSystem.readData(from: indexFileURL)
                let index = try codec.decodeIndex(from: data)
                self.cachedIndex = index
                return index
            } catch {
                logger.warning("Corrupted index file at \(self.indexFileURL.path), rebuilding from records...")
                return try await rebuildIndexFromRecords()
            }
        } else {
            return try await rebuildIndexFromRecords()
        }
    }

    public func rebuildIndexFromRecords() async throws -> RouteStoreIndex {
        var summaries: [RouteSummary] = []

        let contents = (try? fileSystem.contentsOfDirectory(at: storageDirectory)) ?? []
        for url in contents where url.pathExtension.lowercased() == "json" && url.lastPathComponent != "index-v1.json" {
            if let data = try? fileSystem.readData(from: url),
               let record = try? codec.decodeRecord(from: data) {
                summaries.append(record.summary)
            }
        }

        let newIndex = RouteStoreIndex(summaries: summaries, lastUpdated: Date())
        try? await persistIndex(newIndex)
        self.cachedIndex = newIndex
        return newIndex
    }

    private func persistIndex(_ index: RouteStoreIndex) async throws {
        do {
            let data = try codec.encodeIndex(index)
            try fileSystem.writeData(data, to: indexFileURL, atomically: true)
        } catch {
            throw RouteStoreError.writeFailed("Failed to save index-v1.json: \(error.localizedDescription)")
        }
    }

    private func recordFileURL(for id: Route.ID) -> URL {
        let sanitized = id.rawValue.replacingOccurrences(of: ":", with: "_")
        return storageDirectory.appendingPathComponent("\(sanitized).json")
    }
}
