import Foundation

struct RouteFailureMapper: FailureClassifying {
    typealias Failure = UltraNavFailure

    func classify(failure: UltraNavFailure, context: FailureContext) -> FailureClassification {
        switch failure {
        case .routeImport(let importFailure):
            return classifyImportFailure(importFailure, context: context)

        case .routeStore(let storeError):
            return classifyStoreError(storeError, context: context)

        default:
            return FailureClassification(
                id: FailureID(rawValue: "ROUTE-GENERIC-001"),
                severity: .warning,
                impact: .none,
                recoverability: .notRecoverableForCurrentOperation,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Non-route failure routed to RouteFailureMapper"
            )
        }
    }

    private func classifyImportFailure(_ failure: RouteImportFailure, context: FailureContext) -> FailureClassification {
        switch failure {
        case .fileTooLarge(let size, let limit):
            return FailureClassification(
                id: .routeValidationFailed,
                severity: .warning,
                impact: .blocksRouteImport,
                recoverability: .userActionRequired,
                suggestedActions: [.selectAnotherRoute, .dismiss],
                diagnosticMessage: "GPX file size (\(size) bytes) exceeds maximum limit (\(limit) bytes)"
            )

        case .readFailed(let message):
            return FailureClassification(
                id: .routeFileNotFound,
                severity: .warning,
                impact: .blocksRouteImport,
                recoverability: .retryable,
                suggestedActions: [.retry, .selectAnotherRoute],
                diagnosticMessage: "Failed to read route source: \(message)"
            )

        case .parsingFailed:
            return FailureClassification(
                id: .routeMalformedGPX,
                severity: .high,
                impact: .blocksRouteImport,
                recoverability: .userActionRequired,
                suggestedActions: [.selectAnotherRoute, .dismiss],
                diagnosticMessage: "Malformed GPX structure or XML parsing error"
            )

        case .validationFailed, .domainValidationFailed, .normalizationFailed:
            return FailureClassification(
                id: .routeValidationFailed,
                severity: .high,
                impact: .blocksRouteImport,
                recoverability: .userActionRequired,
                suggestedActions: [.selectAnotherRoute, .dismiss],
                diagnosticMessage: "Route geometry or point normalization validation failed"
            )

        case .unknown(let message):
            return FailureClassification(
                id: FailureID(rawValue: "ROUTE-IMPORT-UNKNOWN"),
                severity: .warning,
                impact: .blocksRouteImport,
                recoverability: .notRecoverableForCurrentOperation,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Unknown route import error: \(message)"
            )
        }
    }

    private func classifyStoreError(_ error: RouteStoreError, context: FailureContext) -> FailureClassification {
        switch error {
        case .routeNotFound(let id):
            return FailureClassification(
                id: .routeFileNotFound,
                severity: .high,
                impact: .blocksNavigation,
                recoverability: .userActionRequired,
                suggestedActions: [.selectAnotherRoute, .dismiss],
                diagnosticMessage: "Route not found in store: \(id)"
            )

        case .duplicateRoute:
            return FailureClassification(
                id: .routeDuplicate,
                severity: .informational,
                impact: .none,
                recoverability: .notRecoverableForCurrentOperation,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Route already exists in store"
            )

        case .activeRouteProtected:
            return FailureClassification(
                id: FailureID(rawValue: "ROUTE-PROTECTED-001"),
                severity: .warning,
                impact: .none,
                recoverability: .notRecoverableForCurrentOperation,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Active route is protected from deletion"
            )

        case .invalidRoute, .invalidStorageRecord:
            return FailureClassification(
                id: .routeValidationFailed,
                severity: .high,
                impact: .blocksRouteImport,
                recoverability: .notRecoverableForCurrentOperation,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Stored route record invalid or corrupt"
            )

        case .readFailed(let message):
            return FailureClassification(
                id: .routeFileNotFound,
                severity: .high,
                impact: .blocksNavigation,
                recoverability: .retryable,
                suggestedActions: [.retry, .selectAnotherRoute],
                diagnosticMessage: "Route store read error: \(message)"
            )

        case .writeFailed(let message):
            return FailureClassification(
                id: .routeStoreWriteFailed,
                severity: .high,
                impact: .threatensRidePersistence,
                recoverability: .retryable,
                suggestedActions: [.retry, .dismiss],
                diagnosticMessage: "Route store write error: \(message)"
            )

        case .deleteFailed(let message):
            return FailureClassification(
                id: FailureID(rawValue: "ROUTE-DELETE-001"),
                severity: .warning,
                impact: .none,
                recoverability: .retryable,
                suggestedActions: [.retry, .dismiss],
                diagnosticMessage: "Route store delete error: \(message)"
            )

        case .storageUnavailable:
            return FailureClassification(
                id: FailureID(rawValue: "ROUTE-STORAGE-UNAVAILABLE"),
                severity: .high,
                impact: [.blocksRouteImport, .threatensRidePersistence],
                recoverability: .retryable,
                suggestedActions: [.retry, .dismiss],
                diagnosticMessage: "Route filesystem storage unavailable"
            )

        case .corruptedIndexRebuilt:
            return FailureClassification(
                id: FailureID(rawValue: "ROUTE-INDEX-REBUILT"),
                severity: .informational,
                impact: .none,
                recoverability: .automatic,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Corrupted route index was automatically rebuilt"
            )

        case .unexpected:
            return FailureClassification(
                id: FailureID(rawValue: "ROUTE-UNEXPECTED-001"),
                severity: .warning,
                impact: .none,
                recoverability: .notRecoverableForCurrentOperation,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Unexpected route store error"
            )
        }
    }
}
