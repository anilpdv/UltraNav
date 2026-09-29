#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-UltraNav}"

forbidden_patterns=(
  "CyclingRideEngine"
  "LegacyRideEngineAdapter"
  "LegacyNavigationAdapter"
  "LegacyMetricsAdapter"
  "LegacyClimbAdapter"
  "LegacyRouteLibraryAdapter"
  "BluetoothSensorManager"
  "WorkoutSessionManager"
  "RouteLibraryManager"
  "GPXRoute"
  "LegacyRouteMatcher"
)

failed=0

for pattern in "${forbidden_patterns[@]}"; do
  matches=$(grep -R -n --include='*.swift' "$pattern" "$ROOT" || true)
  if [ -n "$matches" ]; then
    echo "❌ Forbidden legacy symbol remains in $ROOT: $pattern"
    echo "$matches"
    failed=1
  else
    echo "✅ No occurrences of forbidden symbol: $pattern"
  fi
done

if [ "$failed" -eq 0 ]; then
  echo "🎉 All legacy symbol checks passed successfully!"
fi

exit "$failed"
