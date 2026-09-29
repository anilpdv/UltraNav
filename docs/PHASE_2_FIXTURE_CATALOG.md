# Phase 2 Test Fixture Catalog

This catalog documents all synthetic and verified GPX test fixtures used across the UltraNav test suite.

---

## 1. Fixture Categories

| Category | Suite | Scenarios Tested |
|:---|:---|:---|
| **Core Valid** | `GPXParserTests` | Single track, single segment, elevation, timestamps, metadata. |
| **Namespaces** | `GPXParserTests` | Default `xmlns="http://www.topografix.com/GPX/1/1"`, prefixed `xmlns:gpx="http://www.topografix.com/GPX/1/0"`. |
| **Multi-Track & Multi-Segment** | `GPXParserTests`, `StandardGPXContentSelectorTests` | 2+ tracks, 2+ segments per track, `.preferTracks`, `.mergeAllTracks`. |
| **Routes & Waypoints** | `GPXParserTests` | `<rte>` with `<rtept>`, standalone `<wpt>` with `<name>`, `<desc>`, `<sym>`. |
| **Elevation Invariants** | `GPXParserTests`, `RouteNormalizerTests` | Positive elevation, negative elevation (below sea level), missing `<ele>`, corrupted text `<ele>`. |
| **Timestamp Invariants** | `GPXParserTests` | Standard UTC `Z`, millisecond fractional seconds, timezone offsets (`+03:00`), corrupted strings. |
| **Vendor Extensions** | `GPXParserTests` | Garmin `<gpxtpx:TrackPointExtension>` with `<hr>` and `<cad>`. |
| **Duplicate Vertices** | `RouteNormalizerTests` | Consecutive identical samples pruned; distinct timestamps/elevations preserved. |
| **Segment Gap Handling** | `RouteNormalizerTests` | Two tracks 100km apart; verifies cumulative distance does not jump across the gap. |
| **Antimeridian Crossing** | `RouteNormalizerTests` | Track crossing longitude 180°/-180°; triggers antimeridian warning. |
| **Safety Limits** | `GPXParserTests` | Exceeding `maximumFileBytes`, `maximumPointCount`, `maximumElementDepth`. |
| **Large Stress Fixtures** | `GPXLargeFileTests` | `GPXLargeFixtureGenerator` producing 10,000+ point multi-segment tracks. |
