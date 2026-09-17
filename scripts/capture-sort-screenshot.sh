#!/usr/bin/env bash
# Captures docs/screenshots/sort.png for acceptance criterion G10.
# Run from the repo root (or via this script path). Needs a working Simulator.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/docs/screenshots/sort.png"
SCHEME="FlightResults (Fixture)"
DEST="${DESTINATION:-platform=iOS Simulator,name=iPhone 17e,OS=26.5}"
BUNDLE_ID="com.gozayaan.FlightResults"

mkdir -p "$(dirname "$OUT")"

echo "Building $SCHEME…"
xcodebuild \
  -project "$ROOT/FlightResults.xcodeproj" \
  -scheme "$SCHEME" \
  -destination "$DEST" \
  -derivedDataPath "$ROOT/build/DerivedData-sort-capture" \
  -quiet \
  build

APP="$(find "$ROOT/build/DerivedData-sort-capture/Build/Products" -name 'FlightResults.app' -type d | head -1)"
UDID="$(xcrun simctl list devices booted | sed -n 's/.*(\([A-F0-9-]*\)).*/\1/p' | head -1 || true)"
if [[ -z "${UDID}" ]]; then
  echo "Booting iPhone 17e…"
  UDID="$(xcrun simctl list devices available | sed -n 's/.*iPhone 17e (\([A-F0-9-]*\)).*/\1/p' | head -1)"
  open -a Simulator
  xcrun simctl boot "$UDID" 2>/dev/null || true
  xcrun simctl bootstatus "$UDID" -b
fi

xcrun simctl install "$UDID" "$APP"
xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch "$UDID" "$BUNDLE_ID" -- -FRDataSource fixture

echo
echo "Fixture app launched on $UDID."
echo "1. Wait until flight cards appear."
echo "2. Tap Cheapest so the dropdown is open."
echo "3. Return here and press Enter to save the screenshot."
read -r _

xcrun simctl io "$UDID" screenshot "$OUT"
echo "Wrote $OUT"
