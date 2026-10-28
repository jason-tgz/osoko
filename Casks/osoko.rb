cask "osoko" do
  version "1.0.0"
  sha256 "d75d11598c40f5028d81fd562f59ef5614fc03a559a9b709cae2bd4c0a72a6fb"

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
