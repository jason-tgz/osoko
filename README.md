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

## The Problem with macOS Screenshots

Whenever you take a screenshot on a Mac (`⌘⇧4`), you almost always only need it for 10 seconds:
- Dropping a UI bug into Slack or Linear
- Pasting a snippet into a GitHub PR or ChatGPT
- Sending a meme to a friend on Discord
- Copying an error message or tracking number from an image

**What macOS does instead:**
1. It dumps a raw `.png` file straight onto your Desktop.
2. If you take 10 screenshots during a work session, your Desktop becomes littered with files named `Screenshot 2024-10-27 at 11.02.45 AM.png`.
3. A week later, you have 80 meaningless files on your Desktop that you have to manually select, review, and delete.
4. If you turn on Apple's built-in "floating thumbnail", it only shows one screenshot at a time, disappears before you finish switching windows, and blocks buttons underneath it.

---

## How Osoko Fixes It

Osoko intercepts your normal `⌘⇧4` and `⌘⇧5` shortcuts and acts as a **temporary holding shelf**:

1. **You take a screenshot (`⌘⇧4`):** Nothing touches your Desktop. The capture drops into a compact floating card stack in the corner of your screen.
2. **Drag & drop anywhere:** Drag the card directly into Slack, Figma, Discord, GitHub, Chrome, or Finder. Once dropped, Osoko cleans up the temporary file automatically.
3. **Copy text instantly (OCR):** Click the viewfinder icon on any card to extract text, URLs, or code straight to your clipboard using Apple's Vision framework (under 0.15s).
4. **Auto-collapses when you're busy:** If you don't touch the stack for 10 seconds, it tucks itself off the edge of the screen so it's never in your way. Just bump your mouse cursor against the bottom-right edge to slide it back out.
5. **Actually want to save it?** Click the download button or right-click **"Save As..."** to give the file an actual name and save it to your folder of choice.

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
