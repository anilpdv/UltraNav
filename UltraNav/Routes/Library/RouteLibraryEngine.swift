import Foundation
import OSLog

/// Main-actor coordinator managing the lifecycle, listing, importing, and deletion of routes for the presentation layer.
@MainActor
public final class RouteLibraryEngine: RouteLibraryProviding {
    public private(set) var currentSnapshot: RouteLibrarySnapshot {
        didSet {
            snapshotContinuation.yield(currentSnapshot)
        }
    }

    public let snapshots: AsyncStream<RouteLibrarySnapshot>
    private let snapshotContinuation: AsyncStream<RouteLibrarySnapshot>.Continuation

    private let store: any RouteStoring
    private let importer: any RouteImporting
    private let logger = Logger(subsystem: "com.ultranav.routes", category: "RouteLibraryEngine")

    public init(
        store: any RouteStoring = RouteStore(),
        importer: any RouteImporting = RouteImporter()
    ) {
        let streamPair = AsyncStream.makeStream(
            of: RouteLibrarySnapshot.self,
            bufferingPolicy: .bufferingNewest(10)
        )
        self.snapshots = streamPair.stream
        self.snapshotContinuation = streamPair.continuation
        self.store = store
        self.importer = importer

        self.currentSnapshot = .initial
    }

    deinit {
        snapshotContinuation.finish()
    }

    public func send(_ command: RouteLibraryCommand) async {
        switch command {
        case .load, .refresh:
            await loadSummaries()

        case .importSource(let source, let policy):
            await performImport(source: source, policy: policy)

        case .deleteRoute(let id):
            await performDelete(id: id)

        case .selectRoute(let id):
            currentSnapshot = RouteLibrarySnapshot(
                state: currentSnapshot.state,
                routes: currentSnapshot.routes,
                selectedRouteID: id,
                activeRouteID: currentSnapshot.activeRouteID,
                failure: currentSnapshot.failure
            )

        case .setActiveRoute(let id):
            currentSnapshot = RouteLibrarySnapshot(
                state: currentSnapshot.state,
                routes: currentSnapshot.routes,
                selectedRouteID: currentSnapshot.selectedRouteID,
                activeRouteID: id,
                failure: currentSnapshot.failure
            )

        case .clearFailure:
            currentSnapshot = RouteLibrarySnapshot(
                state: currentSnapshot.state,
                routes: currentSnapshot.routes,
                selectedRouteID: currentSnapshot.selectedRouteID,
                activeRouteID: currentSnapshot.activeRouteID,
                failure: nil
            )
        }
    }

    // MARK: - Internal Operations

    private func loadSummaries() async {
        currentSnapshot = RouteLibrarySnapshot(
            state: .loading,
            routes: currentSnapshot.routes,
            selectedRouteID: currentSnapshot.selectedRouteID,
            activeRouteID: currentSnapshot.activeRouteID,
            failure: nil
        )

        do {
            let summaries = try await store.listRoutes()
            currentSnapshot = RouteLibrarySnapshot(
                state: .ready,
                routes: summaries,
                selectedRouteID: currentSnapshot.selectedRouteID,
                activeRouteID: currentSnapshot.activeRouteID,
                failure: nil
            )
        } catch {
            let failure = RouteLibraryFailure.loadFailed(error.localizedDescription)
            currentSnapshot = RouteLibrarySnapshot(
                state: .failed(failure),
                routes: currentSnapshot.routes,
                selectedRouteID: currentSnapshot.selectedRouteID,
                activeRouteID: currentSnapshot.activeRouteID,
                failure: failure
            )
        }
    }

    private func performImport(source: RouteImportSource, policy: RouteImportPolicy) async {
        currentSnapshot = RouteLibrarySnapshot(
            state: .importing,
            routes: currentSnapshot.routes,
            selectedRouteID: currentSnapshot.selectedRouteID,
            activeRouteID: currentSnapshot.activeRouteID,
            failure: nil
        )

        do {
            let importResult = try await importer.importRoute(from: source, policy: policy)
            _ = try await store.saveRoute(importResult.route, behavior: .overwriteExisting)

            let summaries = try await store.listRoutes()
            currentSnapshot = RouteLibrarySnapshot(
                state: .ready,
                routes: summaries,
                selectedRouteID: importResult.route.id,
                activeRouteID: currentSnapshot.activeRouteID,
                failure: nil
            )
        } catch let importFailure as RouteImportFailure {
            let failure = RouteLibraryFailure.importFailed(importFailure)
            currentSnapshot = RouteLibrarySnapshot(
                state: .failed(failure),
                routes: currentSnapshot.routes,
                selectedRouteID: currentSnapshot.selectedRouteID,
                activeRouteID: currentSnapshot.activeRouteID,
                failure: failure
            )
        } catch {
            let failure = RouteLibraryFailure.importFailed(.unknown(error.localizedDescription))
            currentSnapshot = RouteLibrarySnapshot(
                state: .failed(failure),
                routes: currentSnapshot.routes,
                selectedRouteID: currentSnapshot.selectedRouteID,
                activeRouteID: currentSnapshot.activeRouteID,
                failure: failure
            )
        }
    }

    private func performDelete(id: Route.ID) async {
        if let active = currentSnapshot.activeRouteID, active == id {
            let failure = RouteLibraryFailure.activeRouteProtected(id)
            currentSnapshot = RouteLibrarySnapshot(
                state: .failed(failure),
                routes: currentSnapshot.routes,
                selectedRouteID: currentSnapshot.selectedRouteID,
                activeRouteID: currentSnapshot.activeRouteID,
                failure: failure
            )
            return
        }

        currentSnapshot = RouteLibrarySnapshot(
            state: .deleting,
            routes: currentSnapshot.routes,
            selectedRouteID: currentSnapshot.selectedRouteID,
            activeRouteID: currentSnapshot.activeRouteID,
            failure: nil
        )

        do {
            try await store.deleteRoute(id: id, activeRouteID: currentSnapshot.activeRouteID)
            let summaries = try await store.listRoutes()
            let newSelected = currentSnapshot.selectedRouteID == id ? nil : currentSnapshot.selectedRouteID

            currentSnapshot = RouteLibrarySnapshot(
                state: .ready,
                routes: summaries,
                selectedRouteID: newSelected,
                activeRouteID: currentSnapshot.activeRouteID,
                failure: nil
            )
        } catch let storeError as RouteStoreError {
            let failure: RouteLibraryFailure
            switch storeError {
            case .activeRouteProtected(let protectedID):
                failure = .activeRouteProtected(protectedID)
            default:
                failure = .deleteFailed(storeError.localizedDescription)
            }
            currentSnapshot = RouteLibrarySnapshot(
                state: .failed(failure),
                routes: currentSnapshot.routes,
                selectedRouteID: currentSnapshot.selectedRouteID,
                activeRouteID: currentSnapshot.activeRouteID,
                failure: failure
            )
        } catch {
            let failure = RouteLibraryFailure.deleteFailed(error.localizedDescription)
            currentSnapshot = RouteLibrarySnapshot(
                state: .failed(failure),
                routes: currentSnapshot.routes,
                selectedRouteID: currentSnapshot.selectedRouteID,
                activeRouteID: currentSnapshot.activeRouteID,
                failure: failure
            )
        }
    }
}
