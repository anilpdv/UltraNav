import Foundation

enum FailureSeverity: Int, Comparable, Codable, Sendable {
    case informational = 0
    case warning = 1
    case high = 2
    case critical = 3

    static func < (lhs: FailureSeverity, rhs: FailureSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
