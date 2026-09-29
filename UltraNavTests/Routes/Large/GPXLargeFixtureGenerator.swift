import Foundation

/// Deterministic generator for synthetic large GPX tracks for performance and limit stress testing.
enum GPXLargeFixtureGenerator {
    static func makeTrack(pointCount: Int, segmentCount: Int = 1) -> Data {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="UltraNavStress" xmlns="http://www.topografix.com/GPX/1/1">
          <metadata><name>Large Stress Route</name></metadata>
          <trk>
            <name>Stress Track</name>
        """

        let pointsPerSeg = max(1, pointCount / max(1, segmentCount))
        var currentPoint = 0

        for _ in 0..<segmentCount {
            xml += "\n    <trkseg>"
            for _ in 0..<pointsPerSeg {
                if currentPoint >= pointCount { break }
                let lat = 37.0 + Double(currentPoint) * 0.0001
                let lon = -122.0 + Double(currentPoint) * 0.0001
                let ele = 100.0 + Double(currentPoint % 50)
                xml += "\n      <trkpt lat=\"\(lat)\" lon=\"\(lon)\"><ele>\(ele)</ele></trkpt>"
                currentPoint += 1
            }
            xml += "\n    </trkseg>"
        }

        xml += """
          </trk>
        </gpx>
        """

        return xml.data(using: .utf8)!
    }
}
