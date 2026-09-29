import Foundation
import CryptoKit

/// Generates a deterministic SHA256-based RouteID from normalized coordinates and segment breaks.
public final class SHA256RouteIdentityCreator: RouteIdentityCreating, Sendable {
    public init() {}

    public func makeRouteID(points: [Coordinate], segmentBreaks: [Int]) -> RouteID {
        var hasher = SHA256()

        // Format points with fixed precision (6 decimal places = ~0.11m)
        for pt in points {
            let latStr = String(format: "%.6f", pt.latitude)
            let lonStr = String(format: "%.6f", pt.longitude)
            if let latData = latStr.data(using: .utf8), let lonData = lonStr.data(using: .utf8) {
                hasher.update(data: latData)
                hasher.update(data: lonData)
            }
        }

        // Include segment breaks
        for b in segmentBreaks {
            var breakInt = b
            let data = Data(bytes: &breakInt, count: MemoryLayout<Int>.size)
            hasher.update(data: data)
        }

        let digest = hasher.finalize()
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return RouteID(sha256Hex: hex)
    }
}
