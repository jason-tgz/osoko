#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# 1. Build & sign latest release app
"$ROOT/scripts/build-app.sh"

APP="$ROOT/dist/Osoko.app"
DMG="$ROOT/dist/Osoko.dmg"
ZIP="$ROOT/dist/Osoko.zip"

echo "==> Creating distributable ZIP..."
rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

echo "==> Creating distributable DMG..."
rm -f "$DMG"
STAGE_DIR="$(mktemp -d /tmp/osoko-dmg-stage.XXXXXX)"
cp -R "$APP" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create -volname "Osoko" \
    -srcfolder "$STAGE_DIR" \
    -ov -format UDZO \
    "$DMG" >/dev/null

rm -rf "$STAGE_DIR"

echo "=========================================================="
echo " Packaging Complete!"
echo "----------------------------------------------------------"
echo " App Bundle: $APP"
echo " ZIP Archive: $ZIP ($(du -h "$ZIP" | cut -f1))"
echo " DMG Image:   $DMG ($(du -h "$DMG" | cut -f1))"
echo "=========================================================="
