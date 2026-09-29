import Foundation

enum OperationRejection: Error, Equatable, Sendable {
    case invalidState(String)
    case commandAlreadyInProgress
    case operationUnavailable(String)
    case missingRequiredDependency(String)
    case staleRequest
    case cancelled
}
