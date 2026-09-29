#!/usr/bin/env bash
set -euo pipefail

echo "Checking for unreferenced legacy or orphaned source files..."

failed=0
deprecated_files=(
  "UltraNav/Services/Cycling/CyclingRideEngine.swift"
  "UltraNav/Services/Cycling/BluetoothSensorManager.swift"
  "UltraNav/Services/Cycling/WorkoutSessionManager.swift"
  "UltraNav/Services/GPX/GPXParser.swift"
  "UltraNav/Services/GPX/RouteLibraryManager.swift"
  "UltraNav/Models/GPXRoute.swift"
  "UltraNav/Presentation/Ride/LegacyRideEngineAdapter.swift"
  "UltraNav/Presentation/Navigation/LegacyNavigationAdapter.swift"
  "UltraNav/Presentation/Metrics/LegacyMetricsAdapter.swift"
  "UltraNav/Presentation/Climb/LegacyClimbAdapter.swift"
  "UltraNav/Presentation/Routes/LegacyRouteLibraryAdapter.swift"
  "UltraNav/Navigation/Matching/LegacyRouteMatcher.swift"
)

for file in "${deprecated_files[@]}"; do
  if [ -f "$file" ]; then
    echo "❌ Deprecated file still exists on disk: $file"
    failed=1
  fi
done

if [ "$failed" -eq 0 ]; then
  echo "✅ All deprecated files confirmed removed from disk."
fi

exit "$failed"
