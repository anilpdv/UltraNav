#!/usr/bin/env bash
set -euo pipefail

echo "Checking Domain framework boundaries..."
if grep -R -nE 'import (SwiftUI|CoreLocation|CoreBluetooth|HealthKit|WidgetKit)' UltraNav/Domain --include='*.swift'; then
  echo "❌ Domain framework boundary violated: Domain must not import UI or platform frameworks."
  exit 1
fi
echo "✅ Domain framework boundary intact."

echo "Checking Engine platform boundaries..."
if grep -R -nE '\b(CLLocationManager|HKWorkoutSession|CBCentralManager|CBPeripheral)\b' UltraNav/Engines --include='*.swift'; then
  echo "❌ Engine platform boundary violated: Engines must not directly use concrete platform managers."
  exit 1
fi
echo "✅ Engine platform boundary intact."

echo "Checking AppContainer encapsulation..."
if grep -R -n '\bAppContainer\b' UltraNav/Domain UltraNav/Engines UltraNav/Services --include='*.swift'; then
  echo "❌ AppContainer leaked below app composition layer."
  exit 1
fi
echo "✅ AppContainer encapsulation intact."

echo "🎉 All framework boundary checks passed!"
exit 0
