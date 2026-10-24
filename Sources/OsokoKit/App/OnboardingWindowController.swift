import AppKit
import SwiftUI

@MainActor
public final class OnboardingWindowController: NSObject, NSWindowDelegate {
    public static let shared = OnboardingWindowController()

    private var window: NSWindow?

    public func show(force: Bool = false) {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let onboardingView = OnboardingView { [weak self] in
            self?.close()
        }

        let hostingView = NSHostingView(rootView: onboardingView)
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 530),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        newWindow.center()
        newWindow.title = "Osoko Setup"
        newWindow.contentView = hostingView
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        self.window = newWindow

        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func close() {
        window?.orderOut(nil)
        window = nil
    }

    public func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
