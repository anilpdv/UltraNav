import Foundation

enum LogLevel: Int, Comparable, Sendable {
    case trace = 0
    case debug = 1
    case information = 2
    case notice = 3
    case warning = 4
    case error = 5
    case critical = 6

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
