import Foundation

protocol NavigationCueProviding: Sendable {
    func cues(for route: Route) throws -> [NavigationCue]
}
