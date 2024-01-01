import Foundation
import Network
import Observation

@MainActor
@Observable
final class SyncCoordinator {
    enum ConnectivityState: Equatable {
        case checking
        case online
        case offline
    }

    private(set) var connectivityState: ConnectivityState = .checking
    private(set) var pendingMutations: [PendingMutation] = []
    private(set) var lastSuccessfulSync: Date?

    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(
        label: "com.example.UltraNav.connectivity"
    )
    private let cache: AppCache
    private var reconciliationTask: Task<Void, Never>?
    private var restoreTask: Task<Void, Never>?
    private var operation: @Sendable (PendingMutation) async throws -> Void

    init(
        monitor: NWPathMonitor = NWPathMonitor(),
        cache: AppCache = .shared,
        startMonitoring: Bool = true,
        restorePending: Bool = true,
        operation: @escaping @Sendable (PendingMutation) async throws -> Void = { _ in }
    ) {
        self.monitor = monitor
        self.cache = cache
        self.operation = operation
        if restorePending {
            restorePendingMutations()
        }
        if startMonitoring {
            self.startMonitoring()
        }
    }

    var isOnline: Bool {
        connectivityState == .online
    }

    var hasPendingWork: Bool {
        !pendingMutations.isEmpty
    }

    func setReconciliationOperation(
        _ operation: @escaping @Sendable (PendingMutation) async throws -> Void
    ) {
        self.operation = operation
        if isOnline {
            reconcile()
        }
    }

    func enqueue(_ mutation: PendingMutation) {
        pendingMutations.removeAll {
            $0.destination.id == mutation.destination.id
        }
        pendingMutations.append(mutation)
        AppLogger.sync.info(
            "Queued mutation for synchronisation; pending count: \(self.pendingMutations.count, privacy: .public)"
        )

        Task {
            try? await cache.enqueueMutation(mutation)
        }

        if isOnline {
            reconcile()
        }
    }

    func reconcile() {
        guard isOnline, reconciliationTask == nil else { return }

        AppLogger.sync.info("Starting pending mutation reconciliation")
        reconciliationTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                guard
                    self.isOnline,
                    let mutation = self.pendingMutations.first
                else {
                    break
                }

                do {
                    try await self.operation(mutation)
                    guard !Task.isCancelled else { return }
                    self.removePendingMutation(id: mutation.id)
                } catch {
                    AppLogger.sync.error(
                        "Mutation reconciliation failed: \(String(describing: Swift.type(of: error)), privacy: .public)"
                    )
                    self.incrementRetryCount(for: mutation.id)
                    break
                }
            }

            if self.pendingMutations.isEmpty {
                AppLogger.sync.info("Pending mutation reconciliation completed")
                self.lastSuccessfulSync = .now
            }
            self.reconciliationTask = nil
        }
    }

    func cancelReconciliation() {
        reconciliationTask?.cancel()
        reconciliationTask = nil
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }

                let newState: ConnectivityState =
                    path.status == .satisfied ? .online : .offline
                guard newState != self.connectivityState else { return }

                self.connectivityState = newState
                AppLogger.sync.info("Connectivity state changed")
                if newState == .online {
                    self.reconcile()
                } else {
                    self.cancelReconciliation()
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    private func restorePendingMutations() {
        restoreTask = Task { [weak self] in
            guard let self else { return }
            do {
                let restored = try await self.cache.loadPendingMutations() ?? []
                guard !Task.isCancelled else { return }
                self.pendingMutations = restored
                if self.isOnline {
                    self.reconcile()
                }
            } catch {
                AppLogger.sync.error(
                    "Failed to restore pending mutations: \(String(describing: Swift.type(of: error)), privacy: .public)"
                )
                self.pendingMutations = []
            }
        }
    }

    private func removePendingMutation(id: UUID) {
        pendingMutations.removeAll { $0.id == id }
        persistPendingMutations()
    }

    private func incrementRetryCount(for id: UUID) {
        guard let index = pendingMutations.firstIndex(where: { $0.id == id }) else {
            return
        }
        pendingMutations[index].retryCount += 1
        persistPendingMutations()
    }

    private func persistPendingMutations() {
        let mutations = pendingMutations
        Task {
            try? await cache.replacePendingMutations(mutations)
        }
    }
}