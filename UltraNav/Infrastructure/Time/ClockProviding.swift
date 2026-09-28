import Foundation

protocol ClockProviding: Sendable {
    var now: Date { get }
}
