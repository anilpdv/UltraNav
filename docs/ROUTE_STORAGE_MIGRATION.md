# Route Storage Schema & Migration Specification

**Current Schema Version**: V2 (`RouteStorageRecordV2`)  
**Migrator Component**: `RouteStorageMigrator`  

---

## 1. Schema Versions

### Schema V1 (`RouteStorageRecordV1`)
```json
{
  "schemaVersion": 1,
  "route": { ... },
  "summary": { ... }
}
```

### Schema V2 (`RouteStorageRecordV2`)
```json
{
  "schemaVersion": 2,
  "normalizationVersion": "route-normalization-v2",
  "route": { ... },
  "summary": { ... },
  "fingerprints": {
    "geometryID": "...",
    "contentFingerprint": "..."
  },
  "storedAt": "2026-09-29T10:00:00Z"
}
```

---

## 2. Migration Protocol

When `JSONRouteStorageCodec` reads a persisted JSON file:
1. It attempts to decode as `RouteStorageRecordV2`.
2. If decoding fails, it decodes as `RouteStorageRecordV1`.
3. `RouteStorageMigrator` generates `RouteFingerprints` via `SHA256RouteIdentityCreator` and synthesizes a valid `RouteStorageRecordV2`.
4. The migrated V2 record is returned transparently to `RouteStore`.
