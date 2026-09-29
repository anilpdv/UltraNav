#!/usr/bin/env bash
set -euo pipefail

echo "Checking for unauthorized singletons in UltraNav engines, coordinators, and core services..."

forbidden_singletons=(
  "RideEngine"
  "NavigationEngine"
  "MetricsEngine"
  "ClimbEngine"
  "RouteLibraryEngine"
  "CyclingRideEngine"
  "BluetoothSensorManager"
  "WorkoutSessionManager"
  "RouteLibraryManager"
  "RouteStore"
  "RideDataCoordinator"
  "RideLifecycleCoordinator"
  "RouteNavigationCoordinator"
)

failed=0

for type_name in "${forbidden_singletons[@]}"; do
  matches=$(grep -R -nE "static let (shared|instance|defaultInstance).*\b${type_name}\b" UltraNav --include='*.swift' || true)
  if [ -n "$matches" ]; then
    echo "❌ Unauthorized singleton found for ${type_name}:"
    echo "$matches"
    failed=1
  fi
done

if [ "$failed" -eq 0 ]; then
  echo "✅ Zero unauthorized singletons found in Engines, Coordinators, or Domain Services."
fi

exit "$failed"
