import AppKit
import CoreGraphics
import ApplicationServices
import Foundation
import Combine

@MainActor
public final class PermissionsManager: ObservableObject {
    public static let shared = PermissionsManager()

    @Published public private(set) var isScreenRecordingGranted: Bool = false
    @Published public private(set) var isAccessibilityGranted: Bool = false
    @Published public private(set) var isDesktopAccessGranted: Bool = false

    private var pollTimer: Timer?

    public var allPermissionsGranted: Bool {
        isScreenRecordingGranted && isAccessibilityGranted && isDesktopAccessGranted
    }

    private init() {
        refreshStatus()
    }

    public func refreshStatus() {
        self.isScreenRecordingGranted = CGPreflightScreenCaptureAccess()
        self.isAccessibilityGranted = AXIsProcessTrusted()
        self.isDesktopAccessGranted = checkDesktopAccess()
    }

    public func startPolling() {
        stopPolling()
        refreshStatus()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshStatus()
            }
        }
    }

    public func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - Permission Requests
    public func requestScreenRecording() {
        _ = CGRequestScreenCaptureAccess()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refreshStatus()
        }
    }

    public func requestAccessibility() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refreshStatus()
        }
    }

    public func requestDesktopAccess() {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
        // Trigger TCC prompt by listing the directory
        _ = try? FileManager.default.contentsOfDirectory(at: desktop, includingPropertiesForKeys: nil)

        if !checkDesktopAccess() {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_DesktopFolder") {
                NSWorkspace.shared.open(url)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refreshStatus()
        }
    }

    private func checkDesktopAccess() -> Bool {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
        do {
            _ = try FileManager.default.contentsOfDirectory(at: desktop, includingPropertiesForKeys: nil)
            return true
        } catch {
            return false
        }
    }

    // MARK: - App Relaunch
    public static func relaunchApp() {
        let bundlePath = Bundle.main.bundleURL.path
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-n", bundlePath]
        try? process.run()
        NSApp.terminate(nil)
    }
}
