import Foundation

enum MetricsFailure: Error, Equatable, Sendable, Codable {
    case invalidObservation(String)
    case sourceStale(String)
    case aggregationFailed(String)
    case unexpected
}
