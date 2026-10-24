import AppKit
import SwiftUI
import Combine

@MainActor
public final class OsokoAppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private let settings = OsokoSettings.shared
    private let captureService = ScreenshotCaptureService.shared
    private let stack = ScreenshotStack.shared
    private var cancellables: Set<AnyCancellable> = []

    public override init() {
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Prepare floating stack panel
        _ = ScreenshotStackPanel.shared

        // 2. Start directory watchers and inbox redirection
        captureService.startWatchers()

        // 3. Start global hotkey monitoring (⌘⇧S, ⌥⌘S)
        captureService.startGlobalShortcutMonitor()

        // 4. Configure menu bar icon visibility based on user preferences
        updateMenuBarVisibility()

        // 5. Observe setting changes
        settings.onMenuBarSettingChanged = { [weak self] _ in
            self?.updateMenuBarVisibility()
        }

        settings.onInterceptSettingChanged = { [weak self] enabled in
            if enabled {
                self?.captureService.startWatchers()
            } else {
                ScreenshotInbox.restore()
            }
        }
    }

    /// When a headless app is launched again (e.g. from Spotlight, Raycast, Alfred, or Finder),
    /// bring up the Preferences/Settings window instead of launching a second instance.
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        SettingsWindowController.shared.show()
        return true
    }

    public func applicationWillTerminate(_ notification: Notification) {
        captureService.stopWatchers()
        captureService.stopGlobalShortcutMonitor()
        stack.clearAll()
    }

    // MARK: - Menu Bar Item Management
    public func updateMenuBarVisibility() {
        if settings.showMenuBarIcon {
            if statusItem == nil {
                let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                if let button = item.button {
                    button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Osoko")
                    button.imagePosition = .imageOnly
                }
                let menu = buildStatusMenu()
                menu.delegate = self
                item.menu = menu
                statusItem = item
            }
        } else {
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }

    private func buildStatusMenu() -> NSMenu {
        let menu = NSMenu()

        let snipItem = NSMenuItem(title: "Snip Screenshot (⌘⇧S)", action: #selector(snipAction), keyEquivalent: "")
        snipItem.target = self
        menu.addItem(snipItem)

        let windowSnipItem = NSMenuItem(title: "Snip Window (⌥⌘S)", action: #selector(windowSnipAction), keyEquivalent: "")
        windowSnipItem.target = self
        menu.addItem(windowSnipItem)

        let fullScreenItem = NSMenuItem(title: "Capture Full Screen", action: #selector(fullScreenAction), keyEquivalent: "")
        fullScreenItem.target = self
        menu.addItem(fullScreenItem)

        menu.addItem(.separator())

        let count = stack.items.count
        let stackTitle = count == 0 ? "Screenshot Stack (Empty)" : "Screenshot Stack (\(count))"
        let stackItem = NSMenuItem(title: stackTitle, action: #selector(showStackAction), keyEquivalent: "")
        stackItem.target = self
        stackItem.tag = 101
        menu.addItem(stackItem)

        let clearItem = NSMenuItem(title: "Clear Stack", action: #selector(clearStackAction), keyEquivalent: "")
        clearItem.target = self
        clearItem.tag = 102
        clearItem.isEnabled = !stack.items.isEmpty
        menu.addItem(clearItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettingsAction), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Osoko", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    public func menuWillOpen(_ menu: NSMenu) {
        let count = stack.items.count
        if let stackItem = menu.item(withTag: 101) {
            stackItem.title = count == 0 ? "Screenshot Stack (Empty)" : "Screenshot Stack (\(count))"
        }
        if let clearItem = menu.item(withTag: 102) {
            clearItem.isEnabled = count > 0
        }
    }

    // MARK: - Actions
    @objc private func snipAction() {
        captureService.captureInteractive()
    }

    @objc private func windowSnipAction() {
        captureService.captureWindow()
    }

    @objc private func fullScreenAction() {
        captureService.captureFullScreen()
    }

    @objc private func showStackAction() {
        ScreenshotStackPanel.shared.reposition(itemCount: stack.items.count)
    }

    @objc private func clearStackAction() {
        stack.clearAll()
    }

    @objc private func openSettingsAction() {
        SettingsWindowController.shared.show()
    }

    @objc private func quitAction() {
        NSApp.terminate(nil)
    }
}
