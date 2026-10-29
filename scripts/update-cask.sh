#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-1.0.0}"
CASK_FILE="${2:-$ROOT/Casks/osoko.rb}"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Usage: $0 <version, e.g. 1.0.0> [path/to/Casks/osoko.rb]" >&2
    exit 1
fi

# Hash the published artifact: rebuilding a DMG locally changes its checksum.
DMG="$(mktemp /tmp/osoko-cask.XXXXXX)"
trap 'rm -f "$DMG"' EXIT
curl --fail --location --retry 2 \
    "https://github.com/lostmusician/osoko/releases/download/v$VERSION/Osoko.dmg" \
    --output "$DMG"

SHA256="$(shasum -a 256 "$DMG" | cut -d ' ' -f 1)"

echo "==> Updating Homebrew Cask ($VERSION)..."
echo "    SHA256: $SHA256"

mkdir -p "$(dirname "$CASK_FILE")"

cat > "$CASK_FILE" <<EOF
cask "osoko" do
  version "$VERSION"
  sha256 "$SHA256"

  url "https://github.com/lostmusician/osoko/releases/download/v#{version}/Osoko.dmg"
  name "Osoko"
  desc "Temporary floating shelf for macOS screenshots with 1x downscale, OCR, and privacy redaction"
  homepage "https://github.com/lostmusician/osoko"

  depends_on arch: :arm64
  depends_on macos: :sonoma

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
