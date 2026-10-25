import AppKit
import Foundation
import ImageIO

@MainActor
public final class ScreenshotCaptureService {
    public static let shared = ScreenshotCaptureService()

    private let stack: ScreenshotStack
    private var storageWatcher: DirectoryWatcher?
    private var desktopWatcher: DirectoryWatcher?
    private var globalKeyMonitor: Any?
    private var isCapturing = false

    public init(stack: ScreenshotStack = .shared) {
        self.stack = stack
    }

    /// Triggers macOS interactive crosshair screenshot directly into the temporary stack.
    public func captureInteractive() {
        guard !isCapturing else { return }
        isCapturing = true

        let fileName = "Screenshot_\(UUID().uuidString.prefix(8)).png"
        let destinationURL = ScreenshotStack.storageDirectory.appendingPathComponent(fileName)

        Task.detached(priority: .userInitiated) { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            // -i: interactive mode
            process.arguments = ["-i", destinationURL.path]

            do {
                try process.run()
                process.waitUntilExit()

                let success = process.terminationStatus == 0 && FileManager.default.fileExists(atPath: destinationURL.path)

                await MainActor.run {
                    guard let self else { return }
                    self.isCapturing = false
                    if success {
                        SoundPlayer.playShutter()
                        self.stack.add(fileURL: destinationURL)
                    }
                }
            } catch {
                await MainActor.run {
                    self?.isCapturing = false
                }
            }
        }
    }

    /// Triggers macOS interactive window screenshot directly into the temporary stack.
    public func captureWindow() {
        guard !isCapturing else { return }
        isCapturing = true

        let fileName = "Window_\(UUID().uuidString.prefix(8)).png"
        let destinationURL = ScreenshotStack.storageDirectory.appendingPathComponent(fileName)

        Task.detached(priority: .userInitiated) { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            // -i -w: interactive window capture mode
            process.arguments = ["-i", "-w", destinationURL.path]

            do {
                try process.run()
                process.waitUntilExit()

                let success = process.terminationStatus == 0 && FileManager.default.fileExists(atPath: destinationURL.path)

                await MainActor.run {
                    guard let self else { return }
                    self.isCapturing = false
                    if success {
                        SoundPlayer.playShutter()
                        self.stack.add(fileURL: destinationURL)
                    }
                }
            } catch {
                await MainActor.run {
                    self?.isCapturing = false
                }
            }
        }
    }

    /// Captures the full screen immediately.
    public func captureFullScreen() {
        let fileName = "Screen_\(UUID().uuidString.prefix(8)).png"
        let destinationURL = ScreenshotStack.storageDirectory.appendingPathComponent(fileName)

        Task.detached(priority: .userInitiated) { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = [destinationURL.path]

            do {
                try process.run()
                process.waitUntilExit()

                let success = process.terminationStatus == 0 && FileManager.default.fileExists(atPath: destinationURL.path)

                await MainActor.run {
                    guard let self else { return }
                    if success {
                        SoundPlayer.playShutter()
                        self.stack.add(fileURL: destinationURL)
                    }
                }
            } catch {}
        }
    }

    /// Applies inbox preferences so standard Command + Shift + 4 saves directly to Osoko's folder with 0 lag,
    /// and watches both the temporary storage folder and Desktop.
    public func startWatchers() {
        if OsokoSettings.shared.interceptSystemScreenshots {
            ScreenshotInbox.apply(targetDirectory: ScreenshotStack.storageDirectory)
        }

        // 1. Watch temporary storage directory for direct captures
        if storageWatcher == nil {
            let watcher = DirectoryWatcher(url: ScreenshotStack.storageDirectory) { [weak self] file in
                guard Self.isImageFile(file) else { return }
                Task { @MainActor [weak self] in
                    self?.stack.add(fileURL: file)
                }
            }
            storageWatcher = watcher
            watcher.start()
        }

        // 2. Watch Desktop folder to scoop up any screenshots that land there
        if desktopWatcher == nil {
            let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].resolvingSymlinksInPath()
            let watcher = DirectoryWatcher(url: desktop) { file in
                guard Self.isScreenshot(file) else { return }
                guard !ExportTracker.shared.isExported(url: file) else { return }
                let target = ScreenshotStack.storageDirectory.appendingPathComponent(file.lastPathComponent)
                do {
                    if FileManager.default.fileExists(atPath: target.path) {
                        try? FileManager.default.removeItem(at: target)
                    }
                    try FileManager.default.moveItem(at: file, to: target)
                    // Note: storageWatcher automatically monitors storageDirectory and will add target once.
                } catch {}
            }
            desktopWatcher = watcher
            watcher.start()
        }
    }

    public func stopWatchers() {
        storageWatcher?.stop()
        storageWatcher = nil
        desktopWatcher?.stop()
        desktopWatcher = nil
        ScreenshotInbox.restore()
    }

    /// Starts global shortcut monitor for Command + Option + S (Window snip).
    public func startGlobalShortcutMonitor() {
        guard globalKeyMonitor == nil else { return }
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            // Command + Option + S (Window snip)
            if flags == [.command, .option], event.charactersIgnoringModifiers?.lowercased() == "s" {
                Task { @MainActor in self?.captureWindow() }
            }
        }
    }

    public func stopGlobalShortcutMonitor() {
        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyMonitor = nil
        }
    }

    public static func isAccessibilityTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    public static func requestAccessibility() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    nonisolated public static func isFullyWrittenImage(_ url: URL) -> Bool {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return false }
        guard CGImageSourceGetStatus(source) == .statusComplete else { return false }
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return false }
        return cgImage.width > 0 && cgImage.height > 0
    }

    nonisolated public static func isImageFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["png", "jpg", "jpeg", "heic", "webp"].contains(ext)
    }

    nonisolated public static func isScreenshot(_ url: URL) -> Bool {
        guard isImageFile(url) else { return false }
        guard !ExportTracker.shared.isExported(url: url) else { return false }
        let name = url.lastPathComponent
        if name.hasPrefix("Screenshot") || name.hasPrefix("Screen Shot") || name.hasPrefix("Window_") || name.hasPrefix("Screen_") {
            return true
        }
        return url.withUnsafeFileSystemRepresentation { path in
            guard let path else { return false }
            return getxattr(path, "com.apple.metadata:kMDItemIsScreenCapture", nil, 0, 0, 0) >= 0
        }
    }
}
