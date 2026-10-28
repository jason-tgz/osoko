<p align="center">
  <img src="assets/logo.png" alt="Osoko" width="120" height="120">
</p>

<p align="center">
  <img src="assets/wordmark.png" alt="Osoko" width="280">
</p>

<p align="center"><strong>A headless floating shelf for macOS screenshots.</strong></p>

<p align="center">
  <a href="#download-and-get-started">Download</a> ·
  <a href="#how-it-works">How it works</a> ·
  <a href="#shortcuts">Shortcuts</a> ·
  <a href="#on-device-and-private">Privacy</a> ·
  <a href="https://github.com/lostmusician/osoko/issues">Issues</a> ·
  <a href="#license">License</a>
</p>

By default, macOS saves every capture directly to your Desktop, while you could change it to automatically copy them into your clipboard, I still found that it didn't quite suit my needs. So I decided to build my own...

Osoko stores your screenshots in a lightweight stack where you can drag them anywhere, copy them, extract text with local OCR, and let them collapse away for a clean look.

<p align="center">
  <a href="assets/demo.mp4">
    <img src="assets/demo.gif" alt="Osoko demo" width="640">
  </a>
</p>

## How it works

1. **Capture.** Press `⌘⇧3` or `⌘⇧4` as you normally would. Osoko catches your capture into a floating stack instead of saving a file to your Desktop.
2. **Drag or paste.** Drag cards directly into any app ([demo](assets/feature-drag.gif)). Osoko cleans up the temporary file automatically once dropped. You can also hover and press `1` to copy a 1x downscaled image ([demo](assets/feature-copy-image.gif)) so Retina `@2x` captures don't blow out chat widths.
3. **Extract text and links.** Native Apple Vision runs on-device OCR in milliseconds. Hover over a card and press `T` to copy recognized text ([demo](assets/feature-copy-text.gif)). If an item contains a QR code, a quick-action pill lets you open or copy the URL with `L`.
4. **Redact sensitive information.** Press `R` to automatically detect and black out API keys, tokens, emails, and credentials with solid bars before sharing.
5. **Pin or share.** Press `P` on any card to pin it so it stays visible while you reference it ([demo](assets/feature-pin.gif)), or share directly through the native macOS Share menu ([demo](assets/feature-share.gif)).
6. **Fade away.** If you don't interact with the stack, it auto-collapses off-screen. Move your cursor to the corner or take another screenshot to bring it back.

**Hover shortcuts.** Osoko runs as a headless menu bar agent (`LSUIElement`) with no dock icon. You can trigger every common action simply by hovering over a card and pressing a single key—no clicking required.

## Shortcuts

### Global Capture Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `⌘ ⇧ 3` | Screen capture (full screen) |
| `⌘ ⇧ 4` | Region selection capture |
| `⌘ ,` | Settings |

### Hover Shortcuts

Hover your cursor over any card in the stack to trigger instant actions:

| Key | Action |
| :---: | :--- |
| **`1`** | Copy 1x downscaled (halves Retina dimensions for Slack and GitHub) |
| **`2`** or **`C`** | Copy original resolution (Retina 2x) |
| **`T`** | Copy recognized text (OCR) |
| **`R`** | Redact sensitive data (API keys, tokens, emails) |
| **`L`** | Open or copy detected QR code link |
| **`P`** | Toggle pin (keeps the card on screen) |
| **`S`** | Save to disk (`⇧S` for Save As) |
| **`Space`** | Open in Preview |
| **`⌫`** | Dismiss card from stack |

## Download and get started

### Option 1: Homebrew Cask (Recommended)

Homebrew handles installation and Gatekeeper permissions automatically:

```bash
brew install ivanchiew/tap/osoko
```

### Option 2: Direct Download (DMG)

Download **`Osoko.dmg`** from [GitHub Releases](https://github.com/lostmusician/osoko/releases), open it, and drag Osoko to your Applications folder.

Because community release builds are built from open source without a paid Apple Developer ID, macOS Gatekeeper may show a warning on first launch. Right-click `Osoko.app` in `/Applications` and select **Open → Open Anyway**, or run this one-line command in Terminal:

```bash
xattr -cr /Applications/Osoko.app
```

### Permissions

When first opened, Osoko requests two standard macOS permissions:
- **Screen Recording:** Required to capture interactive selection snippets (`⌘⇧4`) and windows.
- **Accessibility:** Required for single-key hover shortcuts (`1`, `T`, `R`, `P`) and the `⌥⌘S` window hotkey.

## On-device and private

- **100% local.** All text recognition (OCR), QR decoding, image downscaling, and privacy redaction run entirely on your Mac using native Apple frameworks.
- **Zero telemetry.** No analytics, no tracking, and zero network calls.
- **Automatic cleanup.** Captures exist in a temporary sandbox directory and are cleaned up when dropped, dismissed, or restarted.

## Support and pricing

Osoko is 100% open source under the MIT License and free to install via Homebrew or build from source.

If you find Osoko useful and want to support ongoing maintenance against future macOS releases, you can purchase a pre-built DMG for **$4.99** on [Gumroad](https://gumroad.com).

## Development

```bash
swift build
swift test
./scripts/package.sh    # creates dist/Osoko.dmg and dist/Osoko.zip
```

Questions, bug reports, and suggestions: [GitHub Issues](https://github.com/lostmusician/osoko/issues).

## License

[MIT](LICENSE)
