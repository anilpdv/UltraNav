import Foundation

/// Canonical element names for GPX document XML elements.
public enum GPXElement: String, Sendable {
    case gpx
    case metadata
    case name
    case description = "desc"
    case time
    case track = "trk"
    case trackSegment = "trkseg"
    case trackPoint = "trkpt"
    case route = "rte"
    case routePoint = "rtept"
    case waypoint = "wpt"
    case elevation = "ele"
    case creator
    case author
    case type
    case number
    case symbol = "sym"
    case extensions

    /// Resolves local element name string (case-insensitive and prefix-stripped) to canonical enum case.
    public static func resolve(localName: String) -> GPXElement? {
        let cleanName = localName.components(separatedBy: ":").last?.lowercased() ?? localName.lowercased()
        return GPXElement(rawValue: cleanName)
    }
}
