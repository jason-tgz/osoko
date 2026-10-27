<p align="center">
  <img src="assets/logo.png" alt="Osoko Logo" width="140" height="140">
</p>

<h1 align="center">Osoko</h1>

<p align="center">
  <strong>The ultra-fast, ghost screenshot shelf & productivity assistant for macOS.</strong><br>
  Capture into a transient floating corner stack, drag directly into any app, extract text with 0.13s Vision OCR, and keep your Desktop 100% clean.
</p>

<p align="center">
  <a href="https://apple.com/macos"><img src="https://img.shields.io/badge/macOS-14.0%2B%20(Sonoma%20%7C%20Sequoia)-000000?style=for-the-badge&logo=apple&logoColor=white" alt="macOS 14+"></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="Swift 6.0"></a>
  <img src="https://img.shields.io/badge/UI-SwiftUI%20%26%20AppKit-0071e3?style=for-the-badge&logo=apple&logoColor=white" alt="SwiftUI & AppKit">
  <img src="https://img.shields.io/badge/Vision%20OCR-0.13s%20Native-00D2FF?style=for-the-badge&logoColor=black" alt="0.13s Vision OCR">
  <img src="https://img.shields.io/badge/Agent-Ghost%20%2F%20Headless-7928CA?style=for-the-badge" alt="Ghost Agent">
  <a href="#-building--packaging"><img src="https://img.shields.io/badge/Release-DMG%20%26%20ZIP-orange?style=for-the-badge" alt="DMG & ZIP"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-success?style=for-the-badge" alt="MIT License"></a>
</p>

---

## 🎬 Walkthrough Demo

<p align="center">
  <a href="assets/demo.mp4">
    <img src="assets/demo.gif" alt="Osoko Demo Walkthrough" width="100%">
  </a>
</p>
<p align="center">
  <em>Native <code>⌘⇧4</code> capture &rarr; floating specular corner shelf &rarr; instant Vision OCR text extraction &rarr; native Share sheet &rarr; direct drag-and-drop into apps &rarr; 10s auto-collapse and edge reveal.</em><br>
  <sub>(Click to watch the full 60fps HD video: <a href="assets/demo.mp4"><code>assets/demo.mp4</code></a>)</sub>
</p>

---

## ✨ Key Features

### 👻 Headless / Ghost Agent by Design
- **Zero Dock Clutter:** Operates as a discreet background agent (`LSUIElement = true`). No Dock icon, no `Cmd + Tab` switcher pollution.
- **Optional Menu Bar Icon:** Dynamic toggle in Preferences. If you prefer a completely clean, pristine menu bar, disable the icon—Osoko stays 100% invisible until invoked.
- **Instant Wakeup:** Summon Settings or Stack anytime from Spotlight, Raycast, Alfred, or terminal (`open -a Osoko`).

### 🪟 Floating Specular Corner Stack
- **Frosted Glass Cards:** Ultra-thin material blur with 1px specular light rim and native spring physics.
- **Dimension Badges:** Pixel-resolution pill (`1280 × 720`) on every captured card.
- **Hover Quick Actions:**
  - 📌 **Pin:** Keeps important screenshots in the stack indefinitely.
  - ⚡ **OCR:** Extracts text, URLs, and code directly to your clipboard in under 130ms.
  - ↗️ **Share:** Opens native macOS sharing extensions (AirDrop, Messages, Mail, Notes).
  - 💾 **Save / Save As:** Fast saving or custom renaming with `NSSavePanel`.
  - ✕ **Dismiss:** Instantly drops the card from the stack.
- **Screenshot Invisibility:** Configured with `sharingType = .none` so floating cards never contaminate subsequent screen captures.

### ⚡ Blazingly Fast Vision OCR (0.13s)
- **Native Apple Neural Engine:** Powered by Apple's `Vision` framework (`VNRecognizeTextRequest`).
- **175x Speedup:** Bypasses slow natural language spellcheck dictionaries to extract text in **0.13 seconds** instead of 26+ seconds.
- **Code & URL Accuracy:** Preserves camelCase variable names, URLs, terminal commands, and syntax without autocorrect interference.
- **Background Pre-Warming:** Captures are analyzed asynchronously upon entry so clicking "Copy Text" is **instantaneous (0ms)**.

### ↗️ Native macOS Share Menu
- Integrated with `NSSharingServicePicker`.
- Share screenshots immediately via **AirDrop**, **Messages**, **Mail**, **Notes**, **Reminders**, or third-party extensions with zero extra configuration.

### 💾 Flexible Saving & File Renaming
- **One-Click Save:** Immediately saves to your default Screenshots / Desktop folder.
- **Save As... (Rename):** Right-click or enable *"Always prompt to rename when saving"* in Settings to choose custom filenames and destinations via `NSSavePanel`.
- **Duplicate Protection:** Integrated with `ExportTracker` using macOS extended file attributes (`xattr`) to prevent saved files from being ingested back into the stack.

### 🖱️ 10-Second Auto-Collapse & Edge Reveal
- **Auto-Collapse:** The floating stack gracefully glides off-screen into the right margin after 10 seconds of inactivity to keep your screen distraction-free.
- **Bottom-Edge Reveal:** Moving your cursor to hit the bottom-right edge of the screen smoothly slides the stack back into view. Hovering over cards cancels the collapse timer.

### 🔄 Direct Drag & Drop Into Any App
- Drag cards directly into **Slack**, **Discord**, **ChatGPT**, **Figma**, **Chrome**, **Safari**, or **Finder**.
- **15-Minute Deferred Cleanup:** Retains temporary files in the background while external applications asynchronously upload or read data, ensuring zero zero-byte drop failures.

### ⌨️ Native Screenshot Interception
- Overrides `com.apple.screencapture` to route standard macOS shortcuts (`⌘⇧4` selection and `⌘⇧5` capture utility) directly into Osoko.
- Cleanly restores your original macOS capture destination upon quitting.
- `⌥⌘S`: Global hotkey for interactive Window Snip.

---

## 🛠️ Building & Packaging

### Prerequisites
- macOS 14.0 (Sonoma) or macOS 15.0 (Sequoia)
- Swift 6.0+ / Xcode 15+

### Build & Package Release (DMG & ZIP)
Run the automated packaging script:

```bash
./scripts/package.sh
```

This compiles a release binary, structures `dist/Osoko.app`, copies `packaging/AppIcon.icns`, signs with your local Apple Development certificate, and produces:
- 📦 **`dist/Osoko.app`** — Standalone macOS Application
- 💿 **`dist/Osoko.dmg`** — Distributable Drag-to-Applications Disk Image
- 🗜️ **`dist/Osoko.zip`** — Distributable ZIP Archive

To install, simply drag `Osoko.app` into `/Applications`:
```bash
cp -R dist/Osoko.app /Applications/
```

---

## ⚙️ Settings & Configuration

To open Settings:
1. Right-click any screenshot card and choose **Settings...** (or press `⌘,`).
2. Click the gear icon on the floating stack toolbar.
3. Launch `Osoko` via Spotlight or Raycast while running.
4. If the menu bar icon is active, click the camera icon &rarr; **Settings...**.

| Preference | Description | Default |
| :--- | :--- | :--- |
| **Show icon in menu bar** | Dynamically attaches or removes the status bar icon | `true` |
| **Always prompt to rename when saving** | Opens `NSSavePanel` on download click for custom names | `false` |
| **Auto-collapse after inactivity** | Collapses stack to the edge after delay | `true` (10s) |
| **Remove from stack after drag & drop** | Automatically consumes cards dropped into apps | `true` |
| **Automatically copy new screenshots** | Copies image to system clipboard immediately on capture | `true` |
| **Play camera sound on capture** | Plays macOS camera shutter sound | `true` |
| **Route macOS shortcuts into Osoko** | Intercepts `⌘⇧4` and `⌘⇧5` captures | `true` |
| **Maximum stack items** | Limit visible cards before pruning unpinned items | `5` |
| **Save Location** | Destination folder for saved screenshots | `~/Desktop` |
| **Launch at Login** | Automatically starts Osoko at system boot | `false` |

---

## 🔐 Permissions Setup

On first launch, Osoko presents an onboarding wizard to configure required macOS permissions:
1. **Screen Recording (`CGRequestScreenCaptureAccess`):** Required to capture snippets and windows. *(Requires a 1-click app restart once granted)*.
2. **Accessibility (`AXIsProcessTrusted`):** Enables global hotkeys (`⌥⌘S`) and bottom-edge screen monitor.
3. **Desktop Access:** Intercepts native captures and saves exported files.

---

## 📄 License

Osoko is open-source software released under the [MIT License](LICENSE).
