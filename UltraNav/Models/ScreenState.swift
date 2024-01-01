import Foundation
import Observation

/// The complete, deterministic lifecycle of an asynchronous screen.
enum ScreenState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(message: String)

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
}

/// Main-actor state controller shared by screens that load user-visible data.
///
/// Starting a new operation cancels obsolete work, while repeated requests can
/// be ignored to prevent duplicate network or location operations.
@MainActor
@Observable
final class ScreenStateController<Value> {
    private(set) var state: ScreenState<Value> = .idle
    private var operationTask: Task<Void, Never>?

    func load(
        allowDuplicateRequest: Bool = false,
        isEmpty: @escaping @MainActor (Value) -> Bool,
        operation: @escaping @MainActor () async throws -> Value
    ) {
        guard allowDuplicateRequest || !state.isLoading else { return }

        operationTask?.cancel()
        state = .loading

        operationTask = Task { @MainActor [weak self] in
            do {
                let value = try await operation()
                guard !Task.isCancelled else { return }
                self?.state = isEmpty(value) ? .empty : .loaded(value)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self?.state = .failed(message: error.localizedDescription)
            }
        }
    }

    func setLoaded(_ value: Value, isEmpty: (Value) -> Bool) {
        operationTask?.cancel()
        operationTask = nil
        state = isEmpty(value) ? .empty : .loaded(value)
    }

    func fail(with message: String) {
        operationTask?.cancel()
        operationTask = nil
        state = .failed(message: message)
    }

    func reset() {
        operationTask?.cancel()
        operationTask = nil
        state = .idle
    }

    func cancel() {
        operationTask?.cancel()
        operationTask = nil

        if state.isLoading {
            state = .idle
        }
    }
}