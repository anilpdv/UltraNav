import Foundation

enum DiagnosticMetadataKey: String, Equatable, Hashable, Sendable {
    case state
    case previousState
    case event
    case operation
    case durationMilliseconds
    case attempt
    case count
    case reason
    case routePointCount
    case segmentCount
    case sensorType
    case failureID
    case subsystem
    case bufferCapacity
    case droppedCount
    case source
}

enum DiagnosticMetadataValue: Equatable, Sendable {
    case string(String)
    case integer(Int)
    case double(Double)
    case boolean(Bool)
    case durationMilliseconds(Double)
    case identifier(String)

    var description: String {
        switch self {
        case .string(let value):
            return value
        case .integer(let value):
            return "\(value)"
        case .double(let value):
            return String(format: "%.3f", value)
        case .boolean(let value):
            return "\(value)"
        case .durationMilliseconds(let value):
            return String(format: "%.2fms", value)
        case .identifier(let value):
            return value
        }
    }
}

struct DiagnosticMetadata: Equatable, Sendable {
    let key: DiagnosticMetadataKey
    let value: DiagnosticMetadataValue
    let privacy: LogPrivacy

    init(key: DiagnosticMetadataKey, value: DiagnosticMetadataValue, privacy: LogPrivacy = .public) {
        self.key = key
        self.value = value
        self.privacy = privacy
    }
}
