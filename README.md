<p align="center">
  <img src="assets/logo.png" alt="Osoko Logo" width="120" height="120">
</p>

<p align="center">
  <img src="assets/wordmark.png" alt="Osoko" width="320">
</p>

<p align="center">
  <strong>A temporary floating shelf for macOS screenshots. No desktop clutter, ever.</strong>
</p>

<p align="center">
  <a href="https://apple.com/macos"><img src="https://img.shields.io/badge/macOS-14.0%2B%20(Sonoma%20%7C%20Sequoia)-000000?style=for-the-badge&logo=apple&logoColor=white" alt="macOS 14+"></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="Swift 6.0"></a>
  <img src="https://img.shields.io/badge/UI-SwiftUI%20%26%20AppKit-0071e3?style=for-the-badge&logo=apple&logoColor=white" alt="SwiftUI & AppKit">
  <img src="https://img.shields.io/badge/OCR-Native%20Apple%20Vision-00D2FF?style=for-the-badge&logoColor=black" alt="Apple Vision OCR">
  <img src="https://img.shields.io/badge/Agent-Ghost%20%2F%20No%20Dock-7928CA?style=for-the-badge" alt="Ghost Agent">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-success?style=for-the-badge" alt="MIT License"></a>
</p>

---

## 🎬 Demo

<p align="center">
  <a href="assets/demo.mp4">
    <img src="assets/demo.gif" alt="Osoko Demo" width="100%">
  </a>
</p>
<p align="center">
  <sub>Hit <code>⌘⇧4</code> &rarr; floating stack &rarr; 1-click OCR &rarr; auto-redact secrets &rarr; scan QR &rarr; copy 1x downscaled &rarr; drag into Slack &rarr; auto-collapses when idle.</sub><br>
  <sub>(Full 60fps HD video: <a href="assets/demo.mp4"><code>assets/demo.mp4</code></a>)</sub>
</p>

---

## Why Osoko?

Most screenshots are temporary: you take one quickly to drop into Slack, paste into a PR or chat, or copy a line of text, and you never need the file again.

By default, macOS saves every capture directly to your Desktop, meaning you regularly have to go in and delete old screenshots. Apple's built-in floating thumbnail also only holds one capture at a time, disappears quickly, and can get in the way of clicks.

**Osoko replaces that with a temporary holding shelf:**
1. **Desktop stays clean:** `⌘⇧4` and `⌘⇧5` captures route straight into a floating corner stack instead of saving to your Desktop.
2. **Drag & drop:** Drag cards directly into Slack, Figma, Discord, GitHub, or any other app. Osoko cleans up the temporary file automatically once dropped.
3. **Copy 1x Downscaled:** Halves Retina `@2x` dimensions so images paste at normal size in Slack, Jira, and GitHub markdown without blowing out widths or eating 10MB of data.
4. **Copy text (OCR):** Click the OCR icon on any card to copy text, links, or code to your clipboard in ~0.1s.
5. **Smart QR & Barcode Detection:** Native Apple Vision automatically recognizes QR codes on screen and gives you a 1-click link to open or copy.
6. **Privacy Shield (Auto-Redact):** 1-click (or tap `R`) to black out detected API keys (`sk-...`, GitHub/AWS tokens), emails, passwords, and tokens with solid black bars.
7. **Out of your way:** If you don't touch the stack, it auto-collapses off-screen after 10 seconds. Move your mouse to the bottom-right corner to bring it back.
8. **Save when you want to:** If you actually want to keep a file, click download or right-click to save and rename it.

---

## Features

- **Ghost Background App:** Runs with `LSUIElement = true`. No Dock icon and no `Cmd + Tab` switcher clutter. You can even hide the menu bar icon in Settings if you want a 100% invisible setup.
- **Retina 1x Downscaler:** Resamples Retina `@2x` captures to logical `@1x` using high-quality CoreGraphics interpolation—preventing giant 200% oversized images in Slack and GitHub PRs.
- **Smart QR Code Scanner:** Background Apple Vision `VNDetectBarcodesRequest` detects QR codes instantly and shows a green glass indicator pill (`QR: example.com`). Press `L` or click to open or copy.
- **Privacy Shield & Redaction:** Automatically detects API keys, tokens, emails, and credentials, and stamps solid black bars over them to keep your shared screenshots secure.
- **Modular Action Slots:** Configure which actions live on the card's 4 toolbar slots (or set unused slots to `None` for an ultra-minimal card).
- **Fast Vision OCR:** Uses Apple's native `VNRecognizeTextRequest` without slow language-correction dictionaries. It runs in ~130ms, handles code syntax and URLs without autocorrect corrupting words, and pre-warms in the background so copying text is immediate.
- **Native macOS Share Menu:** Built-in support for AirDrop, Messages, Mail, and Notes directly from the card hover bar.
- **Save As & Renaming:** Choose whether to save instantly or prompt for a filename with standard `NSSavePanel`.
- **Drag & Drop with Deferred Cleanup:** Retains files for 15 minutes after a drop so external apps (like web browsers or chat clients) finish uploading before deletion.
- **Pinned Cards:** Click the pin icon (`📌`) on any card to keep reference images or palettes in your stack permanently.
- **Stack Pruning:** Automatically keeps your stack capped at whatever limit you choose (default: 5 items).
- **Safe Capture:** The floating stack uses `sharingType = .none` so it never shows up inside new screenshots.

---

## Keyboard Shortcuts

### Global Capture Shortcuts
Osoko intercepts the macOS screenshot daemon cleanly:

| Shortcut | Action |
| :--- | :--- |
| `⌘ ⇧ 4` | **Selection Snip** (routes directly into Osoko stack) |
| `⌘ ⇧ 5` | **macOS Capture Utility** (selection, window, or display) |
| `⌥ ⌘ S` | **Window Snip** (interactive single-window capture) |
| `⌘ ,` | **Preferences / Settings** |

### Single-Key Hover Shortcuts
Hover your mouse over any card in the stack to trigger instant actions without clicking:

| Key | Action | Toast Feedback |
| :---: | :--- | :--- |
| **`1`** | Copy 1x Downscaled (Slack / GitHub) | *Copied 1x ✓* |
| **`2`** or **`C`** | Copy Original 2x (Retina) | *Copied ✓* |
| **`T`** | Copy Text (OCR) | *Text Copied ✓* |
| **`R`** | Redact Sensitive Data (API keys, emails) | *Redacted (n) ✓* |
| **`L`** | Open / Copy QR Code Link | *Opening Link...* |
| **`S`** | Save to configured folder (`⇧S` for Save As) | *Saved ✓* |
| **`P`** | Toggle Pin (keep on stack) | *Pinned 📌* |
| **`Space`** | Open in Preview | — |
| **`⌫`** | Delete / dismiss card from stack | — |

---

## 💖 Support & Pricing (Open Source + Paid Pre-built)

**Osoko is 100% open source under the MIT License.**  
All processing—OCR, QR detection, downscaling, and redaction—runs strictly on-device with zero telemetry and zero network calls.

You have two ways to get Osoko:

1. **Free / Build from Source:** If you have Xcode or the Swift toolchain, you can clone and build the app completely free:
   ```bash
   git clone https://github.com/ivanchiew/osoko.git
   cd osoko && ./scripts/build-app.sh
   ```
2. **Pre-built DMG ($4.99):** If you prefer a pre-built, notarized application bundle that runs out-of-the-box without developer tools, you can purchase it for **$4.99** on [Gumroad](https://gumroad.com) to support ongoing development against new macOS releases.

---

## 🛠️ Build from Source

### Requirements
- macOS 14.0 (Sonoma) or newer
- Swift 6.0+ / Xcode 15+

### Build Distributable App (DMG & ZIP)
Run the release packaging script:

```bash
./scripts/package.sh
```

This compiles a release build, signs the bundle, and outputs:
- **`dist/Osoko.app`**
- **`dist/Osoko.dmg`** (Drag-to-Applications disk image)
- **`dist/Osoko.zip`**

To run locally:
```bash
cp -R dist/Osoko.app /Applications/
open /Applications/Osoko.app
```

---

## License

MIT License. Open source and free to use.
