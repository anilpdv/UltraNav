import Foundation
import CoreLocation

/// Streaming XML parser for GPX course files with automatic turn-cue & climb detection.
public final class GPXParser: NSObject, XMLParserDelegate, Sendable {
    public static func parse(data: Data, defaultName: String = "Offline Course") throws -> GPXRoute {
        let parser = XMLParser(data: data)
        let helper = GPXParserHelper(defaultName: defaultName)
        parser.delegate = helper
        guard parser.parse() else {
            if let error = parser.parserError {
                throw error
            }
            throw NSError(domain: "GPXParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse GPX data"])
        }
        return helper.buildRoute()
    }

    public static func parse(string: String, defaultName: String = "Offline Course") throws -> GPXRoute {
        guard let data = string.data(using: .utf8) else {
            throw NSError(domain: "GPXParser", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 string"])
        }
        return try parse(data: data, defaultName: defaultName)
    }
}

private final class ParserState {
    var routeName: String = "Imported Course"
    var routeDesc: String = ""
    var currentElement = ""
    var currentText = ""

    var currentLat: Double?
    var currentLon: Double?
    var currentEle: Double?
    var currentTime: Date?
    var currentWptName: String?
    var currentWptDesc: String?
    var currentWptSym: String?

    var rawPoints: [(coord: CLLocationCoordinate2D, ele: Double?, time: Date?)] = []
    var waypoints: [(coord: CLLocationCoordinate2D, name: String, desc: String, sym: String)] = []

    let dateFormatter = ISO8601DateFormatter()
}

private final class GPXParserHelper: NSObject, XMLParserDelegate {
    private var state: ParserState
    private let defaultName: String

    init(defaultName: String) {
        self.defaultName = defaultName
        self.state = ParserState()
        self.state.routeName = defaultName
        super.init()
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        state.currentElement = elementName
        state.currentText = ""

        if elementName == "trkpt" || elementName == "rtept" {
            if let latStr = attributeDict["lat"], let lat = Double(latStr),
               let lonStr = attributeDict["lon"], let lon = Double(lonStr) {
                state.currentLat = lat
                state.currentLon = lon
                state.currentEle = nil
                state.currentTime = nil
            }
        } else if elementName == "wpt" {
            if let latStr = attributeDict["lat"], let lat = Double(latStr),
               let lonStr = attributeDict["lon"], let lon = Double(lonStr) {
                state.currentLat = lat
                state.currentLon = lon
                state.currentWptName = nil
                state.currentWptDesc = nil
                state.currentWptSym = nil
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        state.currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let trimmed = state.currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "name":
            if state.currentLat != nil && state.currentWptName == nil {
                state.currentWptName = trimmed
            } else if state.routeName == defaultName && !trimmed.isEmpty {
                state.routeName = trimmed
            }
        case "desc", "cmt":
            if state.currentLat != nil {
                state.currentWptDesc = trimmed
            } else if state.routeDesc.isEmpty {
                state.routeDesc = trimmed
            }
        case "sym":
            state.currentWptSym = trimmed
        case "ele":
            if let ele = Double(trimmed) {
                state.currentEle = ele
            }
        case "time":
            state.currentTime = state.dateFormatter.date(from: trimmed)
        case "trkpt", "rtept":
            if let lat = state.currentLat, let lon = state.currentLon {
                state.rawPoints.append((
                    coord: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    ele: state.currentEle,
                    time: state.currentTime
                ))
            }
            state.currentLat = nil
            state.currentLon = nil
            state.currentEle = nil
            state.currentTime = nil
        case "wpt":
            if let lat = state.currentLat, let lon = state.currentLon {
                state.waypoints.append((
                    coord: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    name: state.currentWptName ?? "Point of Interest",
                    desc: state.currentWptDesc ?? "",
                    sym: state.currentWptSym ?? "generic"
                ))
            }
            state.currentLat = nil
            state.currentLon = nil
        default:
            break
        }
    }

    func buildRoute() -> GPXRoute {
        var processedPoints: [TrackPoint] = []
        var cumulativeDistance: CLLocationDistance = 0
        var totalAscent: Double = 0
        var totalDescent: Double = 0
        var minEle: Double = .infinity
        var maxEle: Double = -.infinity

        for i in 0..<state.rawPoints.count {
            let pt = state.rawPoints[i]
            if i > 0 {
                let prev = state.rawPoints[i - 1]
                let loc1 = CLLocation(latitude: prev.coord.latitude, longitude: prev.coord.longitude)
                let loc2 = CLLocation(latitude: pt.coord.latitude, longitude: pt.coord.longitude)
                let deltaDist = loc2.distance(from: loc1)
                cumulativeDistance += deltaDist

                if let e1 = prev.ele, let e2 = pt.ele {
                    let dEle = e2 - e1
                    if dEle > 0.4 { totalAscent += dEle }
                    else if dEle < -0.4 { totalDescent += abs(dEle) }
                }
            }

            if let ele = pt.ele {
                if ele < minEle { minEle = ele }
                if ele > maxEle { maxEle = ele }
            }

            processedPoints.append(TrackPoint(
                coordinate: pt.coord,
                elevation: pt.ele,
                timestamp: pt.time,
                distanceFromStart: cumulativeDistance
            ))
        }

        if minEle == .infinity { minEle = 0 }
        if maxEle == -.infinity { maxEle = 0 }

        // Generate Turn Cues
        let cues = generateCues(points: processedPoints, waypoints: state.waypoints)

        // Generate ClimbPro segments
        let climbs = generateClimbs(points: processedPoints)

        return GPXRoute(
            name: state.routeName,
            summary: state.routeDesc,
            points: processedPoints,
            cues: cues,
            climbs: climbs,
            totalDistance: cumulativeDistance,
            totalAscent: totalAscent,
            totalDescent: totalDescent,
            minElevation: minEle,
            maxElevation: maxEle
        )
    }

    private func generateCues(
        points: [TrackPoint],
        waypoints: [(coord: CLLocationCoordinate2D, name: String, desc: String, sym: String)]
    ) -> [RouteCue] {
        var cues: [RouteCue] = []

        // 1. Add Start Cue
        if let first = points.first {
            cues.append(RouteCue(
                type: .start,
                instruction: "Start Ride",
                coordinate: first.coordinate,
                distanceFromStart: 0
            ))
        }

        // 2. Add Waypoint cues
        for wpt in waypoints {
            let wptLoc = CLLocation(latitude: wpt.coord.latitude, longitude: wpt.coord.longitude)
            let nearest = points.min {
                CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude).distance(from: wptLoc) <
                CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude).distance(from: wptLoc)
            }
            let dist = nearest?.distanceFromStart ?? 0
            let type: CueType = mapSymbolToCueType(wpt.sym)
            cues.append(RouteCue(
                type: type,
                instruction: wpt.name,
                coordinate: wpt.coord,
                distanceFromStart: dist
            ))
        }

        // 3. Auto-detect major turns from track geometry if cues are scarce
        if points.count > 5 {
            var lastCueDist: CLLocationDistance = 0
            let step = max(1, points.count / 250)

            for i in stride(from: step, to: points.count - step, by: step) {
                let p1 = points[i - step]
                let p2 = points[i]
                let p3 = points[i + step]

                let bearing1 = calculateBearing(from: p1.coordinate, to: p2.coordinate)
                let bearing2 = calculateBearing(from: p2.coordinate, to: p3.coordinate)
                var diff = bearing2 - bearing1
                while diff < -180 { diff += 360 }
                while diff > 180 { diff -= 360 }

                if abs(diff) > 38 && (p2.distanceFromStart - lastCueDist) > 100 {
                    let cueType: CueType
                    let instruction: String
                    if diff > 110 {
                        cueType = .sharpRight
                        instruction = "Sharp Right"
                    } else if diff > 50 {
                        cueType = .right
                        instruction = "Turn Right"
                    } else if diff > 38 {
                        cueType = .slightRight
                        instruction = "Slight Right"
                    } else if diff < -110 {
                        cueType = .sharpLeft
                        instruction = "Sharp Left"
                    } else if diff < -50 {
                        cueType = .left
                        instruction = "Turn Left"
                    } else {
                        cueType = .slightLeft
                        instruction = "Slight Left"
                    }

                    cues.append(RouteCue(
                        type: cueType,
                        instruction: instruction,
                        coordinate: p2.coordinate,
                        distanceFromStart: p2.distanceFromStart
                    ))
                    lastCueDist = p2.distanceFromStart
                }
            }
        }

        // 4. Add End Cue
        if let last = points.last, (last.distanceFromStart - (cues.last?.distanceFromStart ?? 0)) > 50 {
            cues.append(RouteCue(
                type: .end,
                instruction: "Destination / Finish",
                coordinate: last.coordinate,
                distanceFromStart: last.distanceFromStart
            ))
        }

        return cues.sorted { $0.distanceFromStart < $1.distanceFromStart }
    }

    private func generateClimbs(points: [TrackPoint]) -> [ClimbSegment] {
        guard points.count > 10 else { return [] }
        var climbs: [ClimbSegment] = []

        var inClimb = false
        var climbStartIdx = 0
        var climbGain = 0.0

        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]

            guard let e1 = prev.elevation, let e2 = curr.elevation else { continue }
            let dDist = curr.distanceFromStart - prev.distanceFromStart
            let dEle = e2 - e1

            if dDist > 0 {
                let grade = (dEle / dDist) * 100.0
                if grade >= 3.0 {
                    if !inClimb {
                        inClimb = true
                        climbStartIdx = i - 1
                        climbGain = 0
                    }
                    if dEle > 0 { climbGain += dEle }
                } else if inClimb && (grade < 0.5 || i == points.count - 1) {
                    let startPt = points[climbStartIdx]
                    let endPt = points[i]
                    let climbDist = endPt.distanceFromStart - startPt.distanceFromStart
                    let netGain = (endPt.elevation ?? 0) - (startPt.elevation ?? 0)

                    let score = climbDist * (netGain / max(1, climbDist) * 100.0)
                    if climbDist >= 400 && netGain >= 20 && score >= 1200 {
                        let category = categorizeClimb(gain: netGain, distance: climbDist)
                        climbs.append(ClimbSegment(
                            climbIndex: climbs.count + 1,
                            totalClimbs: 0,
                            startDistance: startPt.distanceFromStart,
                            endDistance: endPt.distanceFromStart,
                            startElevation: startPt.elevation ?? 0,
                            endElevation: endPt.elevation ?? 0,
                            category: category
                        ))
                    }
                    inClimb = false
                }
            }
        }

        let total = climbs.count
        return climbs.map {
            var climb = $0
            climb.totalClimbs = total
            return climb
        }
    }

    private func categorizeClimb(gain: Double, distance: Double) -> GPXClimbCategory {
        let score = distance * (gain / max(1, distance) * 100.0)
        if score > 80000 || gain > 1000 { return .hc }
        if score > 64000 || gain > 600 { return .cat1 }
        if score > 32000 || gain > 350 { return .cat2 }
        if score > 16000 || gain > 180 { return .cat3 }
        if score > 8000 || gain > 70 { return .cat4 }
        return .uncategorized
    }

    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radians = atan2(y, x)
        return (radians * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }

    private func mapSymbolToCueType(_ sym: String) -> CueType {
        let s = sym.lowercased()
        if s.contains("water") { return .water }
        if s.contains("food") || s.contains("cafe") { return .food }
        if s.contains("summit") || s.contains("peak") { return .summit }
        if s.contains("danger") || s.contains("hazard") { return .hazard }
        if s.contains("left") { return .left }
        if s.contains("right") { return .right }
        return .generic
    }
}
