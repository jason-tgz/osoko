cask "osoko" do
  version "1.0.0"
  sha256 "8a4a10adf595a0f8fffb212ceb6fc49415de330a0b8327ec9b66522bc48e14cb"

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
