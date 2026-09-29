import Foundation
import Observation

/// Presentation adapter wrapping RouteLibraryProviding with Observable state for SwiftUI views.
@Observable
@MainActor
public final class LegacyRouteLibraryAdapter {
    public private(set) var snapshot: RouteLibrarySnapshot
    private let libraryEngine: any RouteLibraryProviding
    private var observationTask: Task<Void, Never>?

    public init(libraryEngine: any RouteLibraryProviding = RouteLibraryEngine()) {
        self.libraryEngine = libraryEngine
        self.snapshot = libraryEngine.currentSnapshot

        self.observationTask = Task { [weak self] in
            for await snap in libraryEngine.snapshots {
                guard let self else { return }
                self.snapshot = snap
            }
        }
    }

    public var routes: [RouteSummary] {
        snapshot.routes
    }

    public var isLoading: Bool {
        snapshot.state == .loading || snapshot.state == .importing
    }

    public var selectedRouteID: Route.ID? {
        snapshot.selectedRouteID
    }

    public var activeRouteID: Route.ID? {
        snapshot.activeRouteID
    }

    public var failure: RouteLibraryFailure? {
        snapshot.failure
    }

    public func load() {
        Task {
            await libraryEngine.send(.load)
        }
    }

    public func refresh() {
        Task {
            await libraryEngine.send(.refresh)
        }
    }

    public func importSource(_ source: RouteImportSource) {
        Task {
            await libraryEngine.send(.importSource(source))
        }
    }

    public func deleteRoute(id: Route.ID) {
        Task {
            await libraryEngine.send(.deleteRoute(id))
        }
    }

    public func selectRoute(id: Route.ID?) {
        Task {
            await libraryEngine.send(.selectRoute(id))
        }
    }

    public func setActiveRoute(id: Route.ID?) {
        Task {
            await libraryEngine.send(.setActiveRoute(id))
        }
    }

    public func clearFailure() {
        Task {
            await libraryEngine.send(.clearFailure)
        }
    }
}
