#!/usr/bin/env bash
set -euo pipefail

echo "============================================="
echo "       UltraNav Architecture Guard Suite     "
echo "============================================="

echo ""
echo "--- Step 1: Checking Legacy Symbols ---"
bash scripts/check_legacy_symbols.sh UltraNav

echo ""
echo "--- Step 2: Checking Framework Boundaries ---"
bash scripts/check_framework_boundaries.sh

echo ""
echo "--- Step 3: Checking Singletons ---"
bash scripts/check_singletons.sh

echo ""
echo "--- Step 4: Checking Dead Files ---"
bash scripts/check_dead_files.sh

echo ""
echo "============================================="
echo "🎉 UltraNav Architecture Lock-In Passed!     "
echo "============================================="
exit 0
