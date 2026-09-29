import Foundation
import CoreLocation

/// Represents a single point along a track or course.
public struct TrackPoint: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var coordinate: CLLocationCoordinate2D
    public var elevation: Double? // in meters
    public var timestamp: Date?
    public var distanceFromStart: CLLocationDistance // cumulative meters

    enum CodingKeys: String, CodingKey {
        case id, latitude, longitude, elevation, timestamp, distanceFromStart
    }

    public init(
        id: UUID = UUID(),
        coordinate: CLLocationCoordinate2D,
        elevation: Double? = nil,
        timestamp: Date? = nil,
        distanceFromStart: CLLocationDistance = 0
    ) {
        self.id = id
        self.coordinate = coordinate
        self.elevation = elevation
        self.timestamp = timestamp
        self.distanceFromStart = distanceFromStart
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        let lat = try container.decode(Double.self, forKey: .latitude)
        let lon = try container.decode(Double.self, forKey: .longitude)
        self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        self.elevation = try container.decodeIfPresent(Double.self, forKey: .elevation)
        self.timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp)
        self.distanceFromStart = try container.decode(CLLocationDistance.self, forKey: .distanceFromStart)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encodeIfPresent(elevation, forKey: .elevation)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
        try container.encode(distanceFromStart, forKey: .distanceFromStart)
    }

    public static func == (lhs: TrackPoint, rhs: TrackPoint) -> Bool {
        lhs.id == rhs.id &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.elevation == rhs.elevation &&
        lhs.distanceFromStart == rhs.distanceFromStart
    }
}

/// Turn directions and navigation cue types (matching Garmin / Wahoo cue sheets).
public enum CueType: String, Codable, Sendable {
    case straight
    case slightLeft
    case left
    case sharpLeft
    case slightRight
    case right
    case sharpRight
    case uTurn
    case start
    case end
    case summit
    case water
    case food
    case hazard
    case generic

    public var iconName: String {
        switch self {
        case .straight: return "arrow.up"
        case .slightLeft: return "arrow.up.left"
        case .left: return "arrow.turn.up.left"
        case .sharpLeft: return "arrow.turn.left.down"
        case .slightRight: return "arrow.up.right"
        case .right: return "arrow.turn.up.right"
        case .sharpRight: return "arrow.turn.right.down"
        case .uTurn: return "arrow.uturn.left"
        case .start: return "figure.outdoor.cycle"
        case .end: return "flag.checkered"
        case .summit: return "mountain.2.fill"
        case .water: return "drop.fill"
        case .food: return "fork.knife"
        case .hazard: return "exclamationmark.triangle.fill"
        case .generic: return "signpost.right.fill"
        }
    }
}

/// A cue or turn instruction along the route.
public struct RouteCue: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var type: CueType
    public var instruction: String
    public var coordinate: CLLocationCoordinate2D
    public var distanceFromStart: CLLocationDistance // meters from route start

    enum CodingKeys: String, CodingKey {
        case id, type, instruction, latitude, longitude, distanceFromStart
    }

    public init(
        id: UUID = UUID(),
        type: CueType,
        instruction: String,
        coordinate: CLLocationCoordinate2D,
        distanceFromStart: CLLocationDistance
    ) {
        self.id = id
        self.type = type
        self.instruction = instruction
        self.coordinate = coordinate
        self.distanceFromStart = distanceFromStart
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.type = try container.decode(CueType.self, forKey: .type)
        self.instruction = try container.decode(String.self, forKey: .instruction)
        let lat = try container.decode(Double.self, forKey: .latitude)
        let lon = try container.decode(Double.self, forKey: .longitude)
        self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        self.distanceFromStart = try container.decode(CLLocationDistance.self, forKey: .distanceFromStart)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(instruction, forKey: .instruction)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(distanceFromStart, forKey: .distanceFromStart)
    }

    public static func == (lhs: RouteCue, rhs: RouteCue) -> Bool {
        lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.instruction == rhs.instruction &&
        lhs.distanceFromStart == rhs.distanceFromStart
    }
}

/// Climb category similar to Garmin ClimbPro & cycling conventions.
public enum ClimbCategory: String, Codable, Sendable {
    case cat4 = "Cat 4"
    case cat3 = "Cat 3"
    case cat2 = "Cat 2"
    case cat1 = "Cat 1"
    case hc = "HC (Hors Catégorie)"
    case uncategorized = "Climb"

    public var badgeColorHex: String {
        switch self {
        case .cat4: return "#34C759" // Green
        case .cat3: return "#FFD60A" // Yellow
        case .cat2: return "#FF9F0A" // Orange
        case .cat1: return "#FF453A" // Red
        case .hc: return "#BF5AF2"   // Purple
        case .uncategorized: return "#0A84FF" // Blue
        }
    }
}

/// A detected climb along the course (ClimbPro).
public struct ClimbSegment: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var climbIndex: Int // e.g. 1 of 4
    public var totalClimbs: Int
    public var startDistance: CLLocationDistance // meters from route start
    public var endDistance: CLLocationDistance
    public var startElevation: Double // meters
    public var endElevation: Double
    public var category: ClimbCategory

    public var length: CLLocationDistance {
        max(0, endDistance - startDistance)
    }

    public var elevationGain: Double {
        max(0, endElevation - startElevation)
    }

    public var averageGradePercent: Double {
        guard length > 0 else { return 0 }
        return (elevationGain / length) * 100.0
    }

    public init(
        id: UUID = UUID(),
        climbIndex: Int,
        totalClimbs: Int,
        startDistance: CLLocationDistance,
        endDistance: CLLocationDistance,
        startElevation: Double,
        endElevation: Double,
        category: ClimbCategory
    ) {
        self.id = id
        self.climbIndex = climbIndex
        self.totalClimbs = totalClimbs
        self.startDistance = startDistance
        self.endDistance = endDistance
        self.startElevation = startElevation
        self.endElevation = endElevation
        self.category = category
    }
}

/// A complete offline route with points, cues, and elevation profile.
public struct GPXRoute: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var summary: String
    public var points: [TrackPoint]
    public var cues: [RouteCue]
    public var climbs: [ClimbSegment]
    public var totalDistance: CLLocationDistance // meters
    public var totalAscent: Double // meters
    public var totalDescent: Double // meters
    public var minElevation: Double // meters
    public var maxElevation: Double // meters

    public init(
        id: UUID = UUID(),
        name: String,
        summary: String = "",
        points: [TrackPoint],
        cues: [RouteCue] = [],
        climbs: [ClimbSegment] = [],
        totalDistance: CLLocationDistance,
        totalAscent: Double,
        totalDescent: Double,
        minElevation: Double,
        maxElevation: Double
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.points = points
        self.cues = cues
        self.climbs = climbs
        self.totalDistance = totalDistance
        self.totalAscent = totalAscent
        self.totalDescent = totalDescent
        self.minElevation = minElevation
        self.maxElevation = maxElevation
    }

    public var boundingBox: (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        guard !points.isEmpty else { return (0, 0, 0, 0) }
        var minLat = points[0].coordinate.latitude
        var maxLat = points[0].coordinate.latitude
        var minLon = points[0].coordinate.longitude
        var maxLon = points[0].coordinate.longitude

        for pt in points {
            let lat = pt.coordinate.latitude
            let lon = pt.coordinate.longitude
            if lat < minLat { minLat = lat }
            if lat > maxLat { maxLat = lat }
            if lon < minLon { minLon = lon }
            if lon > maxLon { maxLon = lon }
        }
        return (minLat, maxLat, minLon, maxLon)
    }

    func toDomainRoute() -> Route {
        let domainPoints = points.map { pt in
            RoutePoint(
                coordinate: Coordinate(latitude: pt.coordinate.latitude, longitude: pt.coordinate.longitude),
                elevationMeters: pt.elevation,
                timestamp: pt.timestamp,
                cumulativeDistanceMeters: pt.distanceFromStart
            )
        }
        return Route(
            id: id,
            metadata: RouteMetadata(name: name, sourceFileName: nil, createdAt: nil),
            points: domainPoints,
            totalDistanceMeters: totalDistance
        )
    }
}

