# GPX Parsing Policy Specification

**Version**: 2.0 (Phase 2 Standard)  
**Parser Component**: `GPXParserAdapter` & `GPXParserDelegate`  

---

## 1. Safety Bounds & Limits (`GPXParserLimits`)

| Limit Parameter | Default Setting | Rationale |
|:---|:---:|:---|
| `maximumFileBytes` | 25 MB | Prevents memory exhaustion on watchOS. |
| `maximumElementDepth` | 64 | Blocks recursive XML entity expansion & nesting bombs. |
| `maximumPointCount` | 500,000 | Caps total processed points per track/route. |
| `maximumWaypointCount`| 10,000 | Bounds standalone POI/waypoint collections. |
| `maximumTextLength` | 32,768 characters | Prevents runaway string allocations in `<desc>`/`<name>`. |
| `maximumTrackCount` | 1,000 | Caps track count in multi-track GPX collections. |
| `maximumSegmentCount`| 10,000 | Bounds segment splitting memory footprint. |

---

## 2. Tolerant Parsing & Error Recovery (`GPXParsingPolicy`)

- **Invalid Coordinates**: Discarded individually without failing the entire document, unless remaining points < 2.
- **Missing / Malformed Elevation**: Stored as `nil` with aggregated `invalidElevationDiscarded` warning; valid horizontal geometry is preserved.
- **Negative Elevation**: Preserved as valid coordinates (supports below-sea-level riding such as Death Valley or Dead Sea).
- **Malformed Timestamps**: Discarded with aggregated `invalidTimestampDiscarded` warning.
- **Unknown Vendor Extensions (`<extensions>`)**: Subtrees are safely skipped; parser stack depth and integrity are preserved.
- **Missing Version Attribute**: Tolerantly accepted with `missingVersionAccepted` warning.
