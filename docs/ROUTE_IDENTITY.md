# Deterministic Route Identity & Fingerprint Specification

**Algorithm**: Canonical IEEE 754 Big-Endian Binary SHA-256 Hashing  
**Identity Creator**: `SHA256RouteIdentityCreator`  

---

## 1. Primary Geometric RouteID

The primary `RouteID` represents the immutable geometric trajectory of the route. Renaming a route, re-importing from a different filename, or editing descriptions produces the exact same `RouteID`, allowing automated route deduplication.

### Binary Hash Construction:
1. **Normalization Version UTF-8 Prefix**: e.g., `"route-normalization-v2"`
2. **Normalized Point Coordinates**: For each point in sequence:
   - `latitude.bitPattern.bigEndian` (8 bytes)
   - `longitude.bitPattern.bigEndian` (8 bytes)
3. **Segment Separator Marker**: `0xFF` byte
4. **Segment End Indices**: For each segment in sequence:
   - `endPointIndex.bigEndian` (8 bytes)
5. **Output**: 64-character lowercase hexadecimal SHA-256 digest (`RouteID(sha256Hex: ...)`).

---

## 2. Content Fingerprint

The `contentFingerprint` captures full non-geometric metadata and auxiliary streams (elevation, timestamps, waypoints). If a user imports an updated version of a course with enriched elevation profiles or POI markers, the geometry `RouteID` matches while the `contentFingerprint` reflects the update.
