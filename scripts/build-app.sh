#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
cd "$ROOT"

echo "==> Building Osoko ($CONFIGURATION)..."
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT/.build/clang-cache}"
export SWIFTPM_MODULECACHE_OVERRIDE="${SWIFTPM_MODULECACHE_OVERRIDE:-$ROOT/.build/swift-cache}"

swift build --disable-sandbox --configuration "$CONFIGURATION" --product Osoko

BIN_DIR="$(swift build --disable-sandbox --configuration "$CONFIGURATION" --show-bin-path)"
APP="$ROOT/dist/Osoko.app"

echo "==> Packaging $APP..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_DIR/Osoko" "$APP/Contents/MacOS/Osoko"
cp "$ROOT/packaging/Info.plist" "$APP/Contents/Info.plist"
if [ -f "$ROOT/packaging/AppIcon.icns" ]; then
    cp "$ROOT/packaging/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi

for bundle in "$BIN_DIR"/*.bundle; do
    [ -d "$bundle" ] || continue
    cp -R "$bundle" "$APP/Contents/Resources/"
done

SIGNING_IDENTITY="${OSOKO_SIGNING_IDENTITY:-}"
if [ -z "$SIGNING_IDENTITY" ]; then
    # Automatically detect a local Apple Development or code signing certificate so
    # macOS TCC permissions (Accessibility, Screen Recording) persist across rebuilds.
    SIGNING_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | grep -E 'Apple Development:|Developer ID Application:' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/' || true)"
fi

if [ -n "$SIGNING_IDENTITY" ]; then
    echo "==> Signing with certificate: $SIGNING_IDENTITY"
    codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP"
else
    echo "==> Notice: No signing identity found. Signing ad-hoc (-)."
    codesign --force --deep --sign - "$APP"
fi

touch "$APP"
echo "==> Built and signed successfully: $APP"
