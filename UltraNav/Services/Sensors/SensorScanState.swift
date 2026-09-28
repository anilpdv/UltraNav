import Foundation

enum SensorScanState: Equatable, Sendable {
    case idle
    case starting
    case scanning
    case stopping
}
