cask "osoko" do
  version "1.0.1"
  sha256 "1509189bb62c4c5722d6185ac1c50f6d3ad08514965b6f51124e60c260eac176"

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
