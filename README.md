# Osoko

**Osoko** is a lightweight, ultra-fast macOS screenshot shelf and assistant. It captures screenshots into a transient, floating corner stack that you can instantly drag into any application (Slack, Discord, Chrome, ChatGPT, Figma, Finder, etc.), copy to your clipboard, or save to disk—keeping your Desktop 100% clean.

---

## ✨ Features

- **Headless / Ghost Agent by Design:**
  - Zero Dock clutter (`LSUIElement = true`).
  - Optional Menu Bar icon: toggle on or off in Settings. Keep your menu bar completely clean if you prefer!
  - Minimal background resource footprint.
- **Floating Corner Stack:**
  - Specular glass border, native spring transitions, and auto-dismissal.
  - Hover actions: Quick dismiss, Pin to stack, Save to location, and image dimensions badge.
  - Excluded from screenshots (`sharingType = .none`) so the stack never appears in captured images.
- **Fast Interactions:**
  - **Single Click:** Copies image and file URL to the clipboard with animated toast confirmation.
  - **Double Click:** Opens in default image viewer (Preview).
  - **Drag & Drop:** Drag straight into apps with 15-minute deferred cleanup so receiving apps finish reading before deletion.
  - **Right Click Context Menu:** Copy, Save, Pin/Unpin, Open in Preview, Reveal in Finder, Delete, Preferences, Clear Stack, and Quit.
- **System Screencapture Redirection:**
  - Overrides `com.apple.screencapture` to direct native `⌘⇧4` and `⌘⇧5` captures into Osoko with zero lag.
  - Cleanly restores original macOS screenshot settings on quit.
- **Custom Global Shortcuts:**
  - `⌘⇧S`: Interactive crosshair selection.
  - `⌥⌘S`: Interactive window capture.
- **Reopen & Accessibility Integration:**
  - Launching Osoko from Spotlight, Raycast, or Alfred while running brings up the Settings window immediately.

---

## 🛠️ Building & Packaging

### Prerequisites
- macOS 14.0 or newer
- Swift 6.0+ / Xcode 15+

### Build App Bundle
Run the packaging script to produce `dist/Osoko.app`:

```bash
./scripts/build-app.sh
```

The script builds a release binary, structures `Osoko.app`, and signs it with your local Apple Development certificate (or ad-hoc if none is installed).

---

## ⚙️ Settings & Configuration

To open Settings:
1. Press `⌘,` from the right-click menu on any screenshot card.
2. Click the gear icon on the floating stack toolbar.
3. Re-launch `Osoko` via Spotlight, Raycast, or Terminal.
4. If the menu bar icon is enabled, click the camera icon in the menu bar and select **Settings...**.

### Configurable Preferences
- **Show icon in menu bar:** Toggle to show or remove the menu bar icon dynamically.
- **Remove from stack after drag & drop:** Consumes screenshots automatically when dropped into other apps.
- **Automatically copy new screenshots to clipboard:** Copies immediately upon capture.
- **Play camera sound on capture:** Plays shutter sound on snip.
- **Route macOS shortcuts into Osoko:** Directs native captures to the stack.
- **Maximum stack items:** Choose between 1 and 15 visible cards before pruning unpinned items.
- **Save Location:** Custom folder for the "Save to Location" button.
- **Launch at Login:** Register with macOS ServiceManagement.

---

## 📄 License
MIT License.
