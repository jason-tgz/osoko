cask "osoko" do
  version "1.0.0"
  sha256 "5a1e495591c3c3d730154b2e6189e0f1ea73eb06b774906735f47b374dedce29"

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
