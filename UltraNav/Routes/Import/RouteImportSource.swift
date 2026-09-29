import Foundation

/// Defines how raw route data is provided for import.
public enum RouteImportSource: Equatable, Sendable {
    case fileURL(URL)
    case data(Data, originalFileName: String?)
    case bundled(resourceName: String, bundle: Bundle = .main)

    public static func == (lhs: RouteImportSource, rhs: RouteImportSource) -> Bool {
        switch (lhs, rhs) {
        case (.fileURL(let u1), .fileURL(let u2)):
            return u1 == u2
        case (.data(let d1, let f1), .data(let d2, let f2)):
            return d1 == d2 && f1 == f2
        case (.bundled(let r1, let b1), .bundled(let r2, let b2)):
            return r1 == r2 && b1 == b2
        default:
            return false
        }
    }
}
