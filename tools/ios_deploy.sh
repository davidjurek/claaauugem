#!/usr/bin/env bash
# Build PSYCHO SUBURBIA and install it on the connected iPhone.
#
# Prereqs (already true on this machine):
#   - Godot 4.7 at /Applications/Godot.app
#   - Xcode + an Apple ID signed in for team 8WW85L69P3
#   - iPhone paired, Developer Mode ON, unlocked
#
# Usage:  bash tools/ios_deploy.sh
set -euo pipefail

GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
PROJ_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE_ID="${IOS_DEVICE_ID:-00008130-000634362491401C}"   # Seaweed (iPhone 15 Pro)
TEAM="${IOS_TEAM:-8WW85L69P3}"
BUNDLE="com.davidyko.psychosuburbia"
APP="$PROJ_DIR/build/ios/dd/Build/Products/Debug-iphoneos/psychosuburbia.app"

cd "$PROJ_DIR"
echo "==> [1/5] Import resources"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true

echo "==> [2/5] Export Xcode project (Godot)"
rm -rf build/ios/psychosuburbia.xcodeproj build/ios/dd
"$GODOT" --headless --path . --export-debug "iOS" build/ios/psychosuburbia.ipa 2>&1 \
  | grep -iE "Creating build/ios/psychosuburbia.xcodeproj|error|failed" || true

echo "==> [3/5] Build + sign (xcodebuild, team $TEAM)"
xcodebuild \
  -project build/ios/psychosuburbia.xcodeproj \
  -scheme psychosuburbia -configuration Debug \
  -destination "id=$DEVICE_ID" \
  -derivedDataPath build/ios/dd \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM" CODE_SIGN_STYLE=Automatic \
  build 2>&1 | grep -iE "error:|SUCCEEDED|FAILED" || true

echo "==> [4/5] Install to device"
xcrun devicectl device install app --device "$DEVICE_ID" "$APP" 2>&1 | grep -iE "App installed|bundleID|error" || true

echo "==> [5/5] Launch"
xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE" 2>&1 | grep -iE "Launched|error" || true

echo "Done. PSYCHO SUBURBIA should be running on the iPhone."
