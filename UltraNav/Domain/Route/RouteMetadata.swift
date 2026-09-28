import Foundation

struct RouteMetadata: Equatable, Sendable {
    let name: String
    let sourceFileName: String?
    let createdAt: Date?
}
