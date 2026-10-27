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
  <sub>Hit <code>⌘⇧4</code> &rarr; floating stack &rarr; 1-click OCR text copy &rarr; native Share &rarr; drag into Slack/Discord &rarr; auto-collapses when idle.</sub><br>
  <sub>(Full 60fps HD video: <a href="assets/demo.mp4"><code>assets/demo.mp4</code></a>)</sub>
</p>

---

## Why Osoko?

Most screenshots are temporary: you take one quickly to drop into Slack, paste into a PR or chat, or copy a line of text, and you never need the file again.

By default, macOS saves every capture directly to your Desktop, meaning you regularly have to go in and delete old screenshots. Apple's built-in floating thumbnail also only holds one capture at a time, disappears quickly, and can get in the way of clicks.

**Osoko replaces that with a temporary holding shelf:**
1. **Desktop stays clean:** `⌘⇧4` and `⌘⇧5` captures route straight into a floating corner stack instead of saving to your Desktop.
2. **Drag & drop:** Drag cards directly into Slack, Figma, Discord, GitHub, or any other app. Osoko cleans up the temporary file automatically once dropped.
3. **Copy text (OCR):** Click the OCR icon on any card to copy text, links, or code to your clipboard in ~0.1s.
4. **Out of your way:** If you don't touch the stack, it auto-collapses off-screen after 10 seconds. Move your mouse to the bottom-right corner to bring it back.
5. **Save when you want to:** If you actually want to keep a file, click download or right-click to save and rename it.

---

## Features

- **Ghost Background App:** Runs with `LSUIElement = true`. No Dock icon and no `Cmd + Tab` switcher clutter. You can even hide the menu bar icon in Settings if you want a 100% invisible setup.
- **Fast Vision OCR:** Uses Apple's native `VNRecognizeTextRequest` without slow language-correction dictionaries. It runs in ~130ms, handles code syntax and URLs without autocorrect corrupting words, and pre-warms in the background so copying text is immediate.
- **Native macOS Share Menu:** Built-in support for AirDrop, Messages, Mail, and Notes directly from the card hover bar.
- **Save As & Renaming:** Choose whether to save instantly or prompt for a filename with standard `NSSavePanel`.
- **Drag & Drop with Deferred Cleanup:** Retains files for 15 minutes after a drop so external apps (like web browsers or chat clients) finish uploading before deletion.
- **Pinned Cards:** Click the pin icon (`📌`) on any card to keep reference images or palettes in your stack permanently.
- **Stack Pruning:** Automatically keeps your stack capped at whatever limit you choose (default: 5 items).
- **Safe Capture:** The floating stack uses `sharingType = .none` so it never shows up inside new screenshots.

---

## Shortcuts

Osoko intercepts the macOS screenshot daemon cleanly:

| Shortcut | Action |
| :--- | :--- |
| `⌘ ⇧ 4` | **Selection Snip** (routes directly into Osoko stack) |
| `⌘ ⇧ 5` | **macOS Capture Utility** (selection, window, or display) |
| `⌥ ⌘ S` | **Window Snip** (interactive single-window capture) |
| `⌘ ,` | **Preferences / Settings** |

*(When you quit Osoko, your original macOS screenshot settings are cleanly restored).*

---

## Settings

Open settings by:
- Right-clicking any screenshot card &rarr; **Settings...** (`⌘,`)
- Clicking the gear icon on the stack toolbar
- Launching Osoko from Spotlight or Raycast while it's already running

**Options you can configure:**
- **Show icon in menu bar:** Turn off for a completely invisible ghost app.
- **Always prompt to rename when saving:** Pops up a Save dialog to name files.
- **Auto-collapse after inactivity:** Toggle and customize the 10-second slide-away timer.
- **Remove from stack after drag & drop:** Auto-consumes dropped items.
- **Automatically copy new screenshots:** Copies image data to clipboard on capture.
- **Max stack items:** Keep between 1 and 15 visible cards.
- **Save Location:** Custom destination folder (defaults to `~/Desktop`).
- **Launch at Login:** Starts automatically on macOS boot.

---

## 🛠️ Building & Packaging

### Requirements
- macOS 14.0 (Sonoma) or newer
- Swift 6.0+ / Xcode 15+

### Build Distributable App (DMG & ZIP)
Run the release packaging script:

```bash
./scripts/package.sh
```

This compiles a release build, signs the bundle with your local certificate, and outputs:
- **`dist/Osoko.app`**
- **`dist/Osoko.dmg`** (Drag-to-Applications installer)
- **`dist/Osoko.zip`**

To run or install:
```bash
cp -R dist/Osoko.app /Applications/
open /Applications/Osoko.app
```

---

## License

MIT License. Open source and free to use.
