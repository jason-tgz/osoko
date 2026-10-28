#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DMG="$ROOT/dist/Osoko.dmg"
CASK_FILE="$ROOT/Casks/osoko.rb"
VERSION="${1:-1.0.0}"

if [ ! -f "$DMG" ]; then
    echo "Error: $DMG does not exist. Run ./scripts/package.sh first." >&2
    exit 1
fi

SHA256="$(shasum -a 256 "$DMG" | cut -d ' ' -f 1)"

echo "==> Updating Homebrew Cask ($VERSION)..."
echo "    SHA256: $SHA256"

mkdir -p "$(dirname "$CASK_FILE")"

cat > "$CASK_FILE" <<EOF
cask "osoko" do
  version "$VERSION"
  sha256 "$SHA256"

  url "https://github.com/ivanchiew/osoko/releases/download/v#{version}/Osoko.dmg"
  name "Osoko"
  desc "Temporary floating shelf for macOS screenshots with 1x downscale, OCR, and privacy redaction"
  homepage "https://github.com/ivanchiew/osoko"

  depends_on macos: ">= :sonoma"

  app "Osoko.app"

  postflight do
    # Automatically clears macOS Gatekeeper quarantine attribute on install
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/Osoko.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Preferences/com.osoko.screenshot.plist",
    "/tmp/OsokoScreenshots",
  ]
end
EOF

echo "==> Updated $CASK_FILE successfully!"
