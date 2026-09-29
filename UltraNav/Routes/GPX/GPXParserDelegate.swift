import Foundation

/// Parsing context tracking the active structural location in the GPX XML hierarchy.
public enum GPXParserContext: Equatable, Sendable {
    case document
    case metadata
    case track
    case segment
    case route
    case waypoint
    case trackPoint
    case routePoint
    case extensions
    case unknown(String)
}

/// Streaming XMLParserDelegate that constructs a GPXParsedDocument with strict bounds and warning aggregation.
final class GPXParserDelegate: NSObject, XMLParserDelegate {
    private let policy: GPXParsingPolicy
    private let limits: GPXParserLimits
    private let sourceMetadata: GPXSourceMetadata?

    // Context & Text buffer
    private var contextStack: [GPXParserContext] = []
    private var currentText: String = ""

    // Version & Metadata
    private var detectedVersion: GPXVersion?
    private var docName: String?
    private var docDesc: String?
    private var docAuthor: String?
    private var docTime: Date?
    private var docCreator: String?
    private var docKeywords: String?

    // Tracks
    private var tracks: [GPXParsedTrack] = []
    private var currentTrackName: String?
    private var currentTrackDesc: String?
    private var currentSegments: [GPXParsedSegment] = []
    private var currentSegmentPoints: [GPXParsedPoint] = []

    // Routes
    private var routes: [GPXParsedRoute] = []
    private var currentRouteName: String?
    private var currentRouteDesc: String?
    private var currentRoutePoints: [GPXParsedPoint] = []

    // Waypoints
    private var waypoints: [GPXParsedWaypoint] = []
    private var currentWptLat: Double?
    private var currentWptLon: Double?
    private var currentWptEle: Double?
    private var currentWptTime: Date?
    private var currentWptName: String?
    private var currentWptDesc: String?
    private var currentWptSym: String?

    // Active Point fields
    private var activePointLat: Double?
    private var activePointLon: Double?
    private var activePointEle: Double?
    private var activePointTime: Date?

    // Statistics & Warnings
    private var totalTrackPoints = 0
    private var totalRoutePoints = 0
    private var pointsWithElevation = 0
    private var pointsWithTimestamp = 0
    private var invalidElevationCount = 0
    private var invalidTimestampCount = 0
    private var invalidPointCount = 0
    private var unknownElementCounts: [String: Int] = [:]
    private var emptySegmentCount = 0
    private var emptyTrackCount = 0
    private var warnings: [GPXParserWarning] = []

    // Fatal parse error if encountered
    private(set) var fatalError: GPXParserFailure?

    // ISO8601 Formatters per delegate instance
    private let iso8601FormatterWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private let standardISO8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    init(
        policy: GPXParsingPolicy = .standard,
        limits: GPXParserLimits = .watchStandard,
        sourceMetadata: GPXSourceMetadata? = nil
    ) {
        self.policy = policy
        self.limits = limits
        self.sourceMetadata = sourceMetadata
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        guard fatalError == nil else {
            parser.abortParsing()
            return
        }

        if contextStack.count >= limits.maximumElementDepth {
            fatalError = .elementDepthExceeded(depth: contextStack.count, limit: limits.maximumElementDepth)
            parser.abortParsing()
            return
        }

        currentText = ""
        let local = cleanLocalName(elementName: elementName, qName: qName)
        let resolvedElement = GPXElement.resolve(localName: local)

        // Handle Root Element
        if contextStack.isEmpty {
            if resolvedElement != .gpx {
                fatalError = .unsupportedRootElement(elementName)
                parser.abortParsing()
                return
            }

            if let verString = attributeDict["version"] {
                if let ver = GPXVersion(rawValue: verString) {
                    detectedVersion = ver
                } else {
                    warnings.append(.unsupportedVersionAccepted(verString))
                }
            } else {
                warnings.append(.missingVersionAccepted)
            }

            if let creator = attributeDict["creator"] {
                docCreator = creator
            }

            contextStack.append(.document)
            return
        }

        // Inside Document Hierarchy
        switch resolvedElement {
        case .metadata:
            contextStack.append(.metadata)

        case .track:
            if tracks.count >= limits.maximumTrackCount {
                fatalError = .trackLimitExceeded(limit: limits.maximumTrackCount)
                parser.abortParsing()
                return
            }
            currentTrackName = nil
            currentTrackDesc = nil
            currentSegments = []
            contextStack.append(.track)

        case .trackSegment:
            if (tracks.reduce(0) { $0 + $1.segments.count } + currentSegments.count) >= limits.maximumSegmentCount {
                fatalError = .segmentLimitExceeded(limit: limits.maximumSegmentCount)
                parser.abortParsing()
                return
            }
            currentSegmentPoints = []
            contextStack.append(.segment)

        case .trackPoint:
            if totalTrackPoints >= limits.maximumPointCount {
                fatalError = .pointLimitExceeded(limit: limits.maximumPointCount)
                parser.abortParsing()
                return
            }
            startPoint(attributeDict: attributeDict, isTrackPoint: true, parser: parser)
            contextStack.append(.trackPoint)

        case .route:
            currentRouteName = nil
            currentRouteDesc = nil
            currentRoutePoints = []
            contextStack.append(.route)

        case .routePoint:
            if totalRoutePoints >= limits.maximumPointCount {
                fatalError = .pointLimitExceeded(limit: limits.maximumPointCount)
                parser.abortParsing()
                return
            }
            startPoint(attributeDict: attributeDict, isTrackPoint: false, parser: parser)
            contextStack.append(.routePoint)

        case .waypoint:
            if waypoints.count >= limits.maximumWaypointCount {
                fatalError = .waypointLimitExceeded(limit: limits.maximumWaypointCount)
                parser.abortParsing()
                return
            }
            startWaypoint(attributeDict: attributeDict, parser: parser)
            contextStack.append(.waypoint)

        case .extensions:
            contextStack.append(.extensions)

        default:
            contextStack.append(.unknown(local))
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard fatalError == nil else { return }
        if currentText.count + string.count > limits.maximumTextLength {
            let allowed = max(0, limits.maximumTextLength - currentText.count)
            if allowed > 0 {
                currentText.append(String(string.prefix(allowed)))
            }
            warnings.append(.textTruncated(element: contextStack.last.map { "\($0)" } ?? "unknown"))
            return
        }
        currentText.append(string)
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        guard fatalError == nil else { return }

        let local = cleanLocalName(elementName: elementName, qName: qName)
        let resolvedElement = GPXElement.resolve(localName: local)
        let trimmedText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let currentContext = contextStack.popLast() else {
            return
        }

        switch currentContext {
        case .document:
            break

        case .metadata:
            break

        case .track:
            if currentSegments.isEmpty {
                emptyTrackCount += 1
            } else {
                let track = GPXParsedTrack(
                    name: currentTrackName,
                    description: currentTrackDesc,
                    segments: currentSegments
                )
                tracks.append(track)
            }
            currentTrackName = nil
            currentTrackDesc = nil
            currentSegments = []

        case .segment:
            if currentSegmentPoints.isEmpty {
                emptySegmentCount += 1
            } else {
                let segment = GPXParsedSegment(points: currentSegmentPoints)
                currentSegments.append(segment)
            }
            currentSegmentPoints = []

        case .route:
            let route = GPXParsedRoute(
                name: currentRouteName,
                description: currentRouteDesc,
                points: currentRoutePoints
            )
            routes.append(route)
            currentRouteName = nil
            currentRouteDesc = nil
            currentRoutePoints = []

        case .trackPoint:
            commitPoint(isTrackPoint: true)

        case .routePoint:
            commitPoint(isTrackPoint: false)

        case .waypoint:
            commitWaypoint()

        case .extensions:
            break

        case .unknown(let tag):
            // Check if this ended element was an inner property of a parent context
            applyTextValue(element: resolvedElement, tagName: tag, text: trimmedText)
        }
    }

    // MARK: - Point & Waypoint Parsing Helpers

    private func startPoint(attributeDict: [String: String], isTrackPoint: Bool, parser: XMLParser) {
        activePointLat = nil
        activePointLon = nil
        activePointEle = nil
        activePointTime = nil

        guard let latStr = attributeDict["lat"], let lonStr = attributeDict["lon"],
              let lat = Double(latStr), let lon = Double(lonStr),
              lat.isFinite, lon.isFinite,
              lat >= -90.0, lat <= 90.0,
              lon >= -180.0, lon <= 180.0 else {
            if policy.invalidCoordinateBehavior == .rejectDocument {
                fatalError = .invalidRequiredCoordinate
                parser.abortParsing()
            } else {
                invalidPointCount += 1
            }
            return
        }

        activePointLat = lat
        activePointLon = lon
    }

    private func commitPoint(isTrackPoint: Bool) {
        guard let lat = activePointLat, let lon = activePointLon else {
            return
        }

        let point = GPXParsedPoint(
            latitude: lat,
            longitude: lon,
            elevationMeters: activePointEle,
            timestamp: activePointTime
        )

        if point.elevationMeters != nil { pointsWithElevation += 1 }
        if point.timestamp != nil { pointsWithTimestamp += 1 }

        if isTrackPoint {
            currentSegmentPoints.append(point)
            totalTrackPoints += 1
        } else {
            currentRoutePoints.append(point)
            totalRoutePoints += 1
        }
    }

    private func startWaypoint(attributeDict: [String: String], parser: XMLParser) {
        currentWptLat = nil
        currentWptLon = nil
        currentWptEle = nil
        currentWptTime = nil
        currentWptName = nil
        currentWptDesc = nil
        currentWptSym = nil

        guard let latStr = attributeDict["lat"], let lonStr = attributeDict["lon"],
              let lat = Double(latStr), let lon = Double(lonStr),
              lat.isFinite, lon.isFinite,
              lat >= -90.0, lat <= 90.0,
              lon >= -180.0, lon <= 180.0 else {
            if policy.invalidCoordinateBehavior == .rejectDocument {
                fatalError = .invalidRequiredCoordinate
                parser.abortParsing()
            } else {
                invalidPointCount += 1
            }
            return
        }

        currentWptLat = lat
        currentWptLon = lon
    }

    private func commitWaypoint() {
        guard let lat = currentWptLat, let lon = currentWptLon else {
            return
        }

        let wpt = GPXParsedWaypoint(
            latitude: lat,
            longitude: lon,
            elevationMeters: currentWptEle,
            timestamp: currentWptTime,
            name: currentWptName,
            description: currentWptDesc,
            symbol: currentWptSym
        )
        waypoints.append(wpt)
    }

    private func applyTextValue(element: GPXElement?, tagName: String, text: String) {
        guard !text.isEmpty, let parent = contextStack.last else { return }

        switch parent {
        case .metadata:
            switch element {
            case .name: docName = text
            case .description: docDesc = text
            case .author, .creator: docAuthor = text
            case .time: docTime = parseDate(text)
            default: countUnknownElement(tagName)
            }

        case .track:
            switch element {
            case .name: currentTrackName = text
            case .description: currentTrackDesc = text
            default: countUnknownElement(tagName)
            }

        case .route:
            switch element {
            case .name: currentRouteName = text
            case .description: currentRouteDesc = text
            default: countUnknownElement(tagName)
            }

        case .trackPoint, .routePoint:
            switch element {
            case .elevation:
                if let ele = Double(text), ele.isFinite {
                    activePointEle = ele
                } else {
                    invalidElevationCount += 1
                }
            case .time:
                if let date = parseDate(text) {
                    activePointTime = date
                } else {
                    invalidTimestampCount += 1
                }
            default:
                countUnknownElement(tagName)
            }

        case .waypoint:
            switch element {
            case .name: currentWptName = text
            case .description: currentWptDesc = text
            case .symbol: currentWptSym = text
            case .elevation:
                if let ele = Double(text), ele.isFinite {
                    currentWptEle = ele
                } else {
                    invalidElevationCount += 1
                }
            case .time:
                if let date = parseDate(text) {
                    currentWptTime = date
                } else {
                    invalidTimestampCount += 1
                }
            default:
                countUnknownElement(tagName)
            }

        case .document:
            switch element {
            case .name: docName = text
            case .description: docDesc = text
            case .time: docTime = parseDate(text)
            default: countUnknownElement(tagName)
            }

        default:
            countUnknownElement(tagName)
        }
    }

    private func parseDate(_ string: String) -> Date? {
        if let d = iso8601FormatterWithFractionalSeconds.date(from: string) {
            return d
        }
        return standardISO8601Formatter.date(from: string)
    }

    private func countUnknownElement(_ name: String) {
        unknownElementCounts[name, default: 0] += 1
    }

    private func cleanLocalName(elementName: String, qName: String?) -> String {
        let name = qName ?? elementName
        if let colonIndex = name.firstIndex(of: ":") {
            return String(name[name.index(after: colonIndex)...])
        }
        return name
    }

    // MARK: - Report Construction

    func buildReport() -> GPXParsingReport {
        var finalWarnings = warnings

        if invalidElevationCount > 0 {
            finalWarnings.append(.invalidElevationDiscarded(count: invalidElevationCount))
        }
        if invalidTimestampCount > 0 {
            finalWarnings.append(.invalidTimestampDiscarded(count: invalidTimestampCount))
        }
        if invalidPointCount > 0 {
            finalWarnings.append(.invalidPointDiscarded(count: invalidPointCount))
        }
        if emptySegmentCount > 0 {
            finalWarnings.append(.emptySegmentIgnored(count: emptySegmentCount))
        }
        if emptyTrackCount > 0 {
            finalWarnings.append(.emptyTrackIgnored(count: emptyTrackCount))
        }
        for (tag, count) in unknownElementCounts {
            finalWarnings.append(.unknownElementIgnored(name: tag, count: count))
        }

        let document = GPXParsedDocument(
            metadata: GPXSourceMetadata(
                name: docName,
                description: docDesc,
                author: docAuthor,
                time: docTime,
                creator: docCreator,
                originalFileName: sourceMetadata?.originalFileName
            ),
            tracks: tracks,
            routes: routes,
            waypoints: waypoints
        )

        let segmentCount = tracks.reduce(0) { $0 + $1.segments.count }
        let stats = GPXDocumentStatistics(
            trackCount: tracks.count,
            segmentCount: segmentCount,
            trackPointCount: totalTrackPoints,
            routeCount: routes.count,
            routePointCount: totalRoutePoints,
            waypointCount: waypoints.count,
            pointsWithElevation: pointsWithElevation,
            pointsWithTimestamp: pointsWithTimestamp
        )

        return GPXParsingReport(
            document: document,
            version: detectedVersion,
            warnings: finalWarnings,
            statistics: stats
        )
    }
}
