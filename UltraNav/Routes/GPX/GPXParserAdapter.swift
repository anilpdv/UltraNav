import Foundation

/// Conforming implementation of GPXParsing using Apple's XMLParser.
/// Creates an isolated helper per parse request to guarantee concurrency safety.
public final class GPXParserAdapter: GPXParsing, Sendable {
    public init() {}

    public func parse(data: Data) async throws -> GPXParsedDocument {
        guard !data.isEmpty else {
            throw GPXParserFailure.emptyDocument
        }

        let helper = StreamingGPXHelper()
        let parser = XMLParser(data: data)
        parser.delegate = helper
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = false
        parser.shouldResolveExternalEntities = false

        guard parser.parse() else {
            if let error = parser.parserError {
                let nsError = error as NSError
                throw GPXParserFailure.xmlParserError(code: nsError.code, description: nsError.localizedDescription)
            }
            throw GPXParserFailure.malformedXML(message: "Failed to parse XML stream")
        }

        return helper.buildDocument()
    }
}

// MARK: - Streaming XMLParser Helper

private final class StreamingGPXHelper: NSObject, XMLParserDelegate {
    private var elementStack: [String] = []
    private var currentText = ""

    // Metadata accumulation
    private var metaName: String?
    private var metaDesc: String?
    private var metaAuthor: String?
    private var metaTime: Date?
    private var metaKeywords: String?

    // Track accumulation
    private var tracks: [GPXParsedTrack] = []
    private var currentTrackName: String?
    private var currentTrackDesc: String?
    private var currentSegments: [GPXParsedSegment] = []
    private var currentSegmentPoints: [GPXParsedPoint] = []

    // Route accumulation
    private var routes: [GPXParsedRoute] = []
    private var currentRouteName: String?
    private var currentRouteDesc: String?
    private var currentRoutePoints: [GPXParsedPoint] = []

    // Waypoint accumulation
    private var waypoints: [GPXParsedWaypoint] = []
    private var currentWptLat: Double?
    private var currentWptLon: Double?
    private var currentWptName: String?
    private var currentWptDesc: String?
    private var currentWptSym: String?
    private var currentWptEle: Double?
    private var currentWptTime: Date?

    // Active Point accumulation (<trkpt> or <rtept>)
    private var currentPointLat: Double?
    private var currentPointLon: Double?
    private var currentPointEle: Double?
    private var currentPointTime: Date?

    private let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private let fallbackDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    func buildDocument() -> GPXParsedDocument {
        let metadata = GPXSourceMetadata(
            name: metaName,
            description: metaDesc,
            author: metaAuthor,
            time: metaTime,
            creator: nil,
            keywords: metaKeywords
        )
        return GPXParsedDocument(
            metadata: metadata,
            tracks: tracks,
            routes: routes,
            waypoints: waypoints
        )
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        elementStack.append(elementName)
        currentText = ""

        switch elementName {
        case "trk":
            currentTrackName = nil
            currentTrackDesc = nil
            currentSegments = []

        case "trkseg":
            currentSegmentPoints = []

        case "trkpt", "rtept":
            if let latStr = attributeDict["lat"], let lat = Double(latStr),
               let lonStr = attributeDict["lon"], let lon = Double(lonStr) {
                currentPointLat = lat
                currentPointLon = lon
                currentPointEle = nil
                currentPointTime = nil
            }

        case "rte":
            currentRouteName = nil
            currentRouteDesc = nil
            currentRoutePoints = []

        case "wpt":
            if let latStr = attributeDict["lat"], let lat = Double(latStr),
               let lonStr = attributeDict["lon"], let lon = Double(lonStr) {
                currentWptLat = lat
                currentWptLon = lon
                currentWptName = nil
                currentWptDesc = nil
                currentWptSym = nil
                currentWptEle = nil
                currentWptTime = nil
            }

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let parent = elementStack.count > 1 ? elementStack[elementStack.count - 2] : ""

        switch elementName {
        case "name":
            if parent == "metadata" || parent == "gpx" {
                if metaName == nil { metaName = trimmed }
            } else if parent == "trk" {
                currentTrackName = trimmed
            } else if parent == "rte" {
                currentRouteName = trimmed
            } else if parent == "wpt" {
                currentWptName = trimmed
            }

        case "desc", "cmt":
            if parent == "metadata" || parent == "gpx" {
                if metaDesc == nil { metaDesc = trimmed }
            } else if parent == "trk" {
                currentTrackDesc = trimmed
            } else if parent == "rte" {
                currentRouteDesc = trimmed
            } else if parent == "wpt" {
                currentWptDesc = trimmed
            }

        case "author":
            if parent == "metadata" || parent == "gpx" {
                metaAuthor = trimmed
            }

        case "keywords":
            if parent == "metadata" || parent == "gpx" {
                metaKeywords = trimmed
            }

        case "sym":
            if parent == "wpt" {
                currentWptSym = trimmed
            }

        case "ele":
            if let ele = Double(trimmed) {
                if parent == "trkpt" || parent == "rtept" {
                    currentPointEle = ele
                } else if parent == "wpt" {
                    currentWptEle = ele
                }
            }

        case "time":
            let parsedDate = isoDateFormatter.date(from: trimmed) ?? fallbackDateFormatter.date(from: trimmed)
            if parent == "trkpt" || parent == "rtept" {
                currentPointTime = parsedDate
            } else if parent == "wpt" {
                currentWptTime = parsedDate
            } else if parent == "metadata" || parent == "gpx" {
                metaTime = parsedDate
            }

        case "trkpt":
            if let lat = currentPointLat, let lon = currentPointLon {
                currentSegmentPoints.append(GPXParsedPoint(
                    latitude: lat,
                    longitude: lon,
                    elevation: currentPointEle,
                    time: currentPointTime
                ))
            }
            currentPointLat = nil
            currentPointLon = nil
            currentPointEle = nil
            currentPointTime = nil

        case "rtept":
            if let lat = currentPointLat, let lon = currentPointLon {
                currentRoutePoints.append(GPXParsedPoint(
                    latitude: lat,
                    longitude: lon,
                    elevation: currentPointEle,
                    time: currentPointTime
                ))
            }
            currentPointLat = nil
            currentPointLon = nil
            currentPointEle = nil
            currentPointTime = nil

        case "trkseg":
            currentSegments.append(GPXParsedSegment(points: currentSegmentPoints))
            currentSegmentPoints = []

        case "trk":
            tracks.append(GPXParsedTrack(
                name: currentTrackName,
                description: currentTrackDesc,
                segments: currentSegments
            ))
            currentSegments = []

        case "rte":
            routes.append(GPXParsedRoute(
                name: currentRouteName,
                description: currentRouteDesc,
                points: currentRoutePoints
            ))
            currentRoutePoints = []

        case "wpt":
            if let lat = currentWptLat, let lon = currentWptLon {
                waypoints.append(GPXParsedWaypoint(
                    latitude: lat,
                    longitude: lon,
                    name: currentWptName,
                    description: currentWptDesc,
                    symbol: currentWptSym,
                    elevation: currentWptEle,
                    time: currentWptTime
                ))
            }
            currentWptLat = nil
            currentWptLon = nil

        default:
            break
        }

        if !elementStack.isEmpty {
            elementStack.removeLast()
        }
    }
}
