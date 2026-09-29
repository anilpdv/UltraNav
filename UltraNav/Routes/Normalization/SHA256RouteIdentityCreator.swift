import Foundation
import CryptoKit

/// Generates a deterministic SHA256-based RouteID and content fingerprint from normalized coordinates and segments.
public final class SHA256RouteIdentityCreator: RouteIdentityCreating, Sendable {
    public init() {}

    public func makeRouteID(
        points: [Coordinate],
        segmentBreaks: [Int],
        version: RouteNormalizationVersion = .version2
    ) -> RouteID {
        var hasher = SHA256()

        // 1. Version Prefix
        if let vData = version.rawValue.data(using: .utf8) {
            hasher.update(data: vData)
        }

        // 2. Points with normalized IEEE 754 bit pattern (Big Endian)
        for pt in points {
            let latNorm = pt.latitude == 0.0 ? 0.0 : pt.latitude
            let lonNorm = pt.longitude == 0.0 ? 0.0 : pt.longitude

            var latBits = latNorm.bitPattern.bigEndian
            var lonBits = lonNorm.bitPattern.bigEndian

            withUnsafeBytes(of: &latBits) { hasher.update(bufferPointer: $0) }
            withUnsafeBytes(of: &lonBits) { hasher.update(bufferPointer: $0) }
        }

        // 3. Segment breaks separator byte 0xFF followed by break integers
        var sep: UInt8 = 0xFF
        withUnsafeBytes(of: &sep) { hasher.update(bufferPointer: $0) }

        for b in segmentBreaks {
            var breakInt = UInt64(b).bigEndian
            withUnsafeBytes(of: &breakInt) { hasher.update(bufferPointer: $0) }
        }

        let digest = hasher.finalize()
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return RouteID(sha256Hex: hex)
    }

    public func makeFingerprints(
        points: [RoutePoint],
        segments: [RouteSegment],
        waypoints: [RouteWaypoint],
        version: RouteNormalizationVersion = .version2
    ) -> RouteFingerprints {
        let coords = points.map { $0.coordinate }
        let breaks = segments.map { $0.endPointIndex }
        let geoID = makeRouteID(points: coords, segmentBreaks: breaks, version: version).rawValue

        var contentHasher = SHA256()
        let geoData = Data(geoID.utf8)
        contentHasher.update(data: geoData)

        // Add elevation and timestamps
        for pt in points {
            if let ele = pt.elevationMeters {
                var eleBits = ele.bitPattern.bigEndian
                withUnsafeBytes(of: &eleBits) { contentHasher.update(bufferPointer: $0) }
            }
            if let time = pt.timestamp {
                var timeBits = time.timeIntervalSince1970.bitPattern.bigEndian
                withUnsafeBytes(of: &timeBits) { contentHasher.update(bufferPointer: $0) }
            }
        }

        // Add waypoints
        for wpt in waypoints {
            var latBits = wpt.coordinate.latitude.bitPattern.bigEndian
            var lonBits = wpt.coordinate.longitude.bitPattern.bigEndian
            withUnsafeBytes(of: &latBits) { contentHasher.update(bufferPointer: $0) }
            withUnsafeBytes(of: &lonBits) { contentHasher.update(bufferPointer: $0) }
            if let nameData = wpt.name.data(using: .utf8) {
                contentHasher.update(data: nameData)
            }
        }

        let contentDigest = contentHasher.finalize()
        let contentHex = contentDigest.map { String(format: "%02x", $0) }.joined()

        return RouteFingerprints(
            geometryID: geoID,
            contentFingerprint: contentHex
        )
    }
}
