import Foundation
import CoreLocation

/// Manages offline saved courses and starter routes bundled with UltraNav.
@MainActor
public final class RouteLibraryManager {
    public static let shared = RouteLibraryManager()

    private let fileManager = FileManager.default
    private let routesDirectory: URL

    public private(set) var savedRoutes: [GPXRoute] = []

    public init() {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        self.routesDirectory = docs.appendingPathComponent("Routes", isDirectory: true)

        try? fileManager.createDirectory(at: routesDirectory, withIntermediateDirectories: true)
        loadAllRoutes()
    }

    public func loadAllRoutes() {
        var loaded: [GPXRoute] = []

        // 1. Load bundled default routes if empty
        let bundled = SampleRoutes.all
        loaded.append(contentsOf: bundled)

        // 2. Load custom user GPX files from documents
        if let fileURLs = try? fileManager.contentsOfDirectory(at: routesDirectory, includingPropertiesForKeys: nil) {
            for url in fileURLs where url.pathExtension.lowercased() == "gpx" {
                if let data = try? Data(contentsOf: url),
                   let route = try? GPXParser.parse(data: data, defaultName: url.deletingPathExtension().lastPathComponent) {
                    loaded.append(route)
                }
            }
        }

        self.savedRoutes = loaded
    }

    public func importRoute(from gpxString: String, name: String) throws -> GPXRoute {
        let route = try GPXParser.parse(string: gpxString, defaultName: name)
        let fileURL = routesDirectory.appendingPathComponent("\(route.id.uuidString).gpx")
        try gpxString.write(to: fileURL, atomically: true, encoding: .utf8)
        savedRoutes.append(route)
        return route
    }

    public func deleteRoute(id: UUID) {
        savedRoutes.removeAll { $0.id == id }
        let fileURL = routesDirectory.appendingPathComponent("\(id.uuidString).gpx")
        try? fileManager.removeItem(at: fileURL)
    }
}

/// High-quality bundled offline routes with elevation, turns, and climb profiles.
public enum SampleRoutes {
    public static var all: [GPXRoute] {
        [alpineLoop, gravelEpic, coastalGranFondo]
    }

    public static var alpineLoop: GPXRoute {
        let baseLat = 37.3349
        let baseLon = -122.0090
        var points: [TrackPoint] = []
        var cumDist: Double = 0

        // 18km loop with a 450m categorized climb
        let count = 180
        for i in 0..<count {
            let progress = Double(i) / Double(count)
            let angle = progress * 2.0 * .pi
            // Oval loop
            let lat = baseLat + (sin(angle) * 0.045) + (sin(angle * 3) * 0.005)
            let lon = baseLon + (cos(angle) * 0.065) - 0.03

            // Rising climb in first section (0 to 25) from 150m to 385m (steep 5% grade)
            let ele: Double
            if i <= 25 {
                let climbProg = Double(i) / 25.0
                ele = 150.0 + (climbProg * 235.0)
            } else if i <= 60 {
                let descProg = Double(i - 25) / 35.0
                ele = 385.0 - (descProg * 220.0)
            } else {
                let flatProg = Double(i - 60) / 120.0
                ele = 165.0 + (sin(flatProg * .pi * 4) * 20.0)
            }

            if i > 0 {
                let prev = points[i - 1]
                let loc1 = CLLocation(latitude: prev.coordinate.latitude, longitude: prev.coordinate.longitude)
                let loc2 = CLLocation(latitude: lat, longitude: lon)
                cumDist += loc2.distance(from: loc1)
            }

            points.append(TrackPoint(
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                elevation: ele,
                distanceFromStart: cumDist
            ))
        }

        let cues = [
            RouteCue(type: .start, instruction: "Start Alpine Loop Ride", coordinate: points[0].coordinate, distanceFromStart: 0),
            RouteCue(type: .right, instruction: "Turn Right on Ridge Trail", coordinate: points[10].coordinate, distanceFromStart: points[10].distanceFromStart),
            RouteCue(type: .summit, instruction: "King's Mountain Summit (Cat 2)", coordinate: points[25].coordinate, distanceFromStart: points[25].distanceFromStart),
            RouteCue(type: .sharpRight, instruction: "Caution: Sharp Switchback Downhill", coordinate: points[45].coordinate, distanceFromStart: points[45].distanceFromStart),
            RouteCue(type: .water, instruction: "Water & Aid Station", coordinate: points[100].coordinate, distanceFromStart: points[100].distanceFromStart),
            RouteCue(type: .end, instruction: "Finish Alpine Loop", coordinate: points.last!.coordinate, distanceFromStart: cumDist)
        ]

        let climbs = [
            ClimbSegment(
                climbIndex: 1,
                totalClimbs: 1,
                startDistance: points[0].distanceFromStart,
                endDistance: points[25].distanceFromStart,
                startElevation: points[0].elevation ?? 150,
                endElevation: points[25].elevation ?? 385,
                category: .cat2
            )
        ]

        return GPXRoute(
            name: "Alpine King's Loop",
            summary: "18.2 km • 420m Climb • Scenic Ridge & Fast Descent",
            points: points,
            cues: cues,
            climbs: climbs,
            totalDistance: cumDist,
            totalAscent: 420,
            totalDescent: 418,
            minElevation: 120,
            maxElevation: 385
        )
    }

    public static var gravelEpic: GPXRoute {
        let baseLat = 37.3500
        let baseLon = -122.0500
        var points: [TrackPoint] = []
        var cumDist: Double = 0

        let count = 120
        for i in 0..<count {
            let progress = Double(i) / Double(count)
            let lat = baseLat + (sin(progress * .pi * 2) * 0.03)
            let lon = baseLon + (progress * 0.06)
            let ele = 80.0 + (sin(progress * .pi * 4) * 60.0)

            if i > 0 {
                let prev = points[i - 1]
                let loc1 = CLLocation(latitude: prev.coordinate.latitude, longitude: prev.coordinate.longitude)
                let loc2 = CLLocation(latitude: lat, longitude: lon)
                cumDist += loc2.distance(from: loc1)
            }

            points.append(TrackPoint(
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                elevation: ele,
                distanceFromStart: cumDist
            ))
        }

        let cues = [
            RouteCue(type: .start, instruction: "Start Gravel Trailhead", coordinate: points[0].coordinate, distanceFromStart: 0),
            RouteCue(type: .hazard, instruction: "Rough Gravel & Rocks", coordinate: points[30].coordinate, distanceFromStart: points[30].distanceFromStart),
            RouteCue(type: .left, instruction: "Turn Left onto Fire Road", coordinate: points[60].coordinate, distanceFromStart: points[60].distanceFromStart),
            RouteCue(type: .end, instruction: "Trailhead Parking", coordinate: points.last!.coordinate, distanceFromStart: cumDist)
        ]

        return GPXRoute(
            name: "Foothills Gravel Epic",
            summary: "12.5 km • 180m Climb • Rolling Gravel & Singletrack",
            points: points,
            cues: cues,
            climbs: [],
            totalDistance: cumDist,
            totalAscent: 185,
            totalDescent: 180,
            minElevation: 60,
            maxElevation: 145
        )
    }

    public static var coastalGranFondo: GPXRoute {
        let baseLat = 37.3100
        let baseLon = -122.0800
        var points: [TrackPoint] = []
        var cumDist: Double = 0

        let count = 150
        for i in 0..<count {
            let progress = Double(i) / Double(count)
            let lat = baseLat + (progress * 0.07)
            let lon = baseLon + (sin(progress * .pi * 3) * 0.02)
            let ele = 20.0 + (sin(progress * .pi * 2) * 35.0)

            if i > 0 {
                let prev = points[i - 1]
                let loc1 = CLLocation(latitude: prev.coordinate.latitude, longitude: prev.coordinate.longitude)
                let loc2 = CLLocation(latitude: lat, longitude: lon)
                cumDist += loc2.distance(from: loc1)
            }

            points.append(TrackPoint(
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                elevation: ele,
                distanceFromStart: cumDist
            ))
        }

        let cues = [
            RouteCue(type: .start, instruction: "Depart Harbor Front", coordinate: points[0].coordinate, distanceFromStart: 0),
            RouteCue(type: .straight, instruction: "Continue on Ocean Highway", coordinate: points[45].coordinate, distanceFromStart: points[45].distanceFromStart),
            RouteCue(type: .right, instruction: "Turn Right towards Coastal Overlook", coordinate: points[90].coordinate, distanceFromStart: points[90].distanceFromStart),
            RouteCue(type: .end, instruction: "Lighthouse Overlook", coordinate: points.last!.coordinate, distanceFromStart: cumDist)
        ]

        return GPXRoute(
            name: "Pacific Coastal Breeze",
            summary: "15.8 km • 95m Climb • Flat Coastal Highway & Ocean Views",
            points: points,
            cues: cues,
            climbs: [],
            totalDistance: cumDist,
            totalAscent: 95,
            totalDescent: 90,
            minElevation: 10,
            maxElevation: 58
        )
    }
}
