
import MapKit

extension MKDirectionsTransportType {
    var name: String {
        switch self {
        case .automobile:
            return "driving"
        case .walking:
            return "walking"
        case .cycling:
            return "cycling"
        default:
            return ""
        }
    }

    var symbol: String {
        switch self {
        case .automobile:
            return "car"
        case .walking:
            return "figure.walk"
        case .cycling:
            return "bicycle"
        default:
            return "questionmark"
        }
    }
}
