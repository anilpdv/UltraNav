# GPX Format Support Matrix

**Specification Baseline**: GPX 1.0 & GPX 1.1 (Topografix)  
**Target Parser**: UltraNav Native Streaming GPX Pipeline  

---

## 1. Feature Support Matrix

| GPX Feature / Tag | Support Level | Implementation Behavior |
|:---|:---:|:---|
| **GPX 1.1 Root (`<gpx version="1.1">`)** | `SUPPORTED` | Fully parsed; version extracted into report. |
| **GPX 1.0 Root (`<gpx version="1.0">`)** | `SUPPORTED` | Fully parsed; version extracted into report. |
| **Missing Version Attribute** | `SUPPORTED` | Tolerantly accepted with `unsupportedVersionAccepted` warning. |
| **Future / Unknown Version** | `SUPPORTED` | Tolerantly parsed with `unsupportedVersionAccepted` warning if valid XML. |
| **Default XML Namespaces (`xmlns="..."`)** | `SUPPORTED` | Elements resolved by local name (`localName`). |
| **Prefixed Namespaces (`xmlns:gpx="..."`)** | `SUPPORTED` | Prefix stripped; elements matched by local name. |
| **Document Metadata (`<metadata>`)** | `SUPPORTED` | Extracts `<name>`, `<desc>`, `<time>`, `<author>`, `<creator>`. |
| **Tracks (`<trk>`)** | `SUPPORTED` | Preserves individual tracks with `<name>`, `<desc>`, and multiple `<trkseg>`. |
| **Track Segments (`<trkseg>`)** | `SUPPORTED` | Preserves segment boundaries; prevents false distance jumps. |
| **Track Points (`<trkpt>`)** | `SUPPORTED` | Parses required `lat`/`lon`, optional `<ele>`, optional `<time>`. |
| **Routes (`<rte>`)** | `SUPPORTED` | Preserves routes with `<name>`, `<desc>`, and `<rtept>` list. |
| **Route Points (`<rtept>`)** | `SUPPORTED` | Parses required `lat`/`lon`, optional `<ele>`, optional `<time>`. |
| **Waypoints (`<wpt>`)** | `SUPPORTED` | Preserves waypoints (`name`, `ele`, `time`, `symbol`) separately from polyline. |
| **Negative Elevation** | `SUPPORTED` | Valid; accurately represents below-sea-level tracks. |
| **Missing / Malformed Elevation** | `SUPPORTED` | Discards invalid elevation with aggregated warning; retains valid point coordinates. |
| **ISO 8601 Timestamps** | `SUPPORTED` | Parses UTC (`Z`), fractional seconds, and timezone offsets (`+HH:MM`). |
| **Missing / Malformed Timestamps**| `SUPPORTED` | Discards invalid timestamp with aggregated warning; retains valid point coordinates. |
| **Unknown Vendor Extensions (`<extensions>`)** | `IGNORED SAFELY` | Skips subtree cleanly without failing XML parser; emits warning. |
| **XML Entity / Billion Laughs Attacks**| `REJECTED` | Blocked via `shouldResolveExternalEntities = false` and `maximumElementDepth` limit. |
| **Files Exceeding Max Bytes / Points** | `REJECTED` | Fails fast with `fileTooLarge` or `pointLimitExceeded`. |

---

## 2. Content Selection Policy

| Policy | Behavior |
|:---|:---|
| `.preferTracks` (Default) | Selects single track, or longest track if multiple exist (with warning); falls back to route if no tracks exist. |
| `.preferRoutes` | Selects single route, or longest route if multiple exist (with warning); falls back to track if no routes exist. |
| `.firstTrack` | Deterministically selects the first `<trk>` in document order. |
| `.longestTrack` | Selects `<trk>` with the highest point count. |
| `.mergeAllTracks` | Concatenates all track segments into a multi-segment route while preserving segment boundaries. |
| `.requireExplicitSelection` | Emits candidates for UI picker if multiple tracks/routes are found. |
