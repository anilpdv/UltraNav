import Foundation

enum LogMetadataValue: Equatable, Sendable {
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

struct LogMetadataEntry: Equatable, Sendable {
    let key: String
    let value: LogMetadataValue
    let privacy: LogPrivacy

    init(key: String, value: LogMetadataValue, privacy: LogPrivacy = .public) {
        self.key = key
        self.value = value
        self.privacy = privacy
    }

    func renderedValue(redactingSensitive: Bool = true) -> String {
        switch privacy {
        case .public:
            return value.description
        case .privateData:
            return value.description
        case .sensitive:
            return redactingSensitive ? "<redacted>" : value.description
        }
    }
}
