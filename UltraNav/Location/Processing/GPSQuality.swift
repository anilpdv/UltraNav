import Foundation

/// Quality classification of a GPS location fix based on horizontal accuracy.
public enum GPSQuality: String, Equatable, Hashable, Codable, Sendable {
    case excellent
    case good
    case usable
    case poor

    public static func classify(horizontalAccuracyMeters: Double) -> GPSQuality {
        switch horizontalAccuracyMeters {
        case ...5.0:
            return .excellent
        case 5.0..<10.0:
            return .good
        case 10.0..<25.0:
            return .usable
        default:
            return .poor
        }
    }
}
