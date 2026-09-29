import Foundation

/// Defines behavior when saving a route whose ID already exists in storage.
public enum RouteSaveBehavior: Equatable, Sendable {
    case failIfExists
    case overwriteExisting
}

/// The outcome of a saveRoute operation.
public enum RouteSaveOutcome: Equatable, Sendable {
    case savedNew
    case overwritten
}
