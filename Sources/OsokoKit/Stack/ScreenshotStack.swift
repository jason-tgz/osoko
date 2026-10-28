import AppKit
import Foundation

@MainActor
public final class ScreenshotStack: ObservableObject {
    public static let shared = ScreenshotStack()

    @Published public private(set) var items: [ScreenshotItem] = []
    @Published public var toastMessage: (id: UUID, text: String)?

    nonisolated public static let storageDirectory: URL = {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .resolvingSymlinksInPath()
            .appendingPathComponent("OsokoScreenshots", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    public init() {
        Self.cleanupOldTemporaryFiles()
    }

    @discardableResult
    public func add(fileURL: URL) -> ScreenshotItem? {
        let resolvedURL = fileURL.standardizedFileURL.resolvingSymlinksInPath()

        // Do not add files that were exported by Osoko
        if ExportTracker.shared.isExported(url: resolvedURL) {
            return nil
        }

        // Prevent duplicate items for the same file path (checking resolved paths)
        if let existing = items.first(where: { $0.url.standardizedFileURL.resolvingSymlinksInPath().path == resolvedURL.path }) {
            return existing
        }

        // Efficient memory thumbnail: read metadata and downsample for UI display
        guard let source = CGImageSourceCreateWithURL(resolvedURL as CFURL, nil) else { return nil }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return nil }
        let pixelWidth = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
        let pixelHeight = properties[kCGImagePropertyPixelHeight] as? Int ?? 0
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }

        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 450
        ]
        guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary) else { return nil }
        let thumbnail = NSImage(cgImage: cgThumb, size: NSSize(width: pixelWidth, height: pixelHeight))

        let item = ScreenshotItem(
            url: resolvedURL,
            thumbnail: thumbnail,
            pixelWidth: max(1, pixelWidth),
            pixelHeight: max(1, pixelHeight)
        )

        // Newest capture enters top of stack
        items.insert(item, at: 0)

        // Pre-warm OCR recognition in background so copying text is instantaneous
        TextRecognitionService.prewarm(imageURL: resolvedURL)

        // If auto-copy is enabled, copy immediately
        if OsokoSettings.shared.autoCopyToClipboard {
            copy(id: item.id, showToastFeedback: false)
        }

        // Prune down to maxItems, keeping pinned ones
        let maxAllowed = max(1, OsokoSettings.shared.maxStackItems)
        if items.count > maxAllowed {
            for i in stride(from: items.count - 1, through: 0, by: -1) {
                if items.count <= maxAllowed { break }
                if !items[i].isPinned {
                    let old = items.remove(at: i)
                    try? FileManager.default.removeItem(at: old.url)
                }
            }
        }

        // Expand stack and start 10s auto-collapse countdown
        StackCollapseState.shared.onNewScreenshotAdded()

        return item
    }

    public func remove(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let item = items.remove(at: index)
        TextRecognitionService.clearCache(for: item.url)
        try? FileManager.default.removeItem(at: item.url)
        if items.isEmpty {
            StackCollapseState.shared.stopEdgeMonitoring()
        }
    }

    public func consumeDrop(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        guard OsokoSettings.shared.consumeOnDrop else { return }

        if !items[index].isPinned {
            let item = items.remove(at: index)
            // Deferred cleanup: When dropping into external applications (e.g. ChatGPT, Slack, Discord, Chrome, Finder),
            // the receiving app reads/uploads the file asynchronously AFTER the drag session finishes.
            // If the file is deleted immediately, the app reads 0 bytes and fails.
            // Retain the file for a generous 15-minute window for deferred cleanup.
            scheduleDeferredCleanup(for: item.url, delaySeconds: 900)
        }
    }

    private func scheduleDeferredCleanup(for fileURL: URL, delaySeconds: TimeInterval) {
        Task.detached(priority: .background) {
            try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            if fileURL.path.hasPrefix(ScreenshotStack.storageDirectory.path) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }

    nonisolated public static func cleanupOldTemporaryFiles(maxAge: TimeInterval = 3600) {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: storageDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let threshold = Date().addingTimeInterval(-maxAge)
        for file in files {
            let values = try? file.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey])
            let date = values?.contentModificationDate ?? values?.creationDate ?? .distantPast
            if date < threshold {
                try? fm.removeItem(at: file)
            }
        }
    }

    public func togglePin(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isPinned.toggle()
        showToast(id: id, text: items[index].isPinned ? "Pinned 📌" : "Unpinned")
    }

    public func copy(id: UUID, showToastFeedback: Bool = true) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let image = NSImage(contentsOf: item.url) {
            pasteboard.writeObjects([image, item.url as NSURL])
        } else {
            pasteboard.writeObjects([item.url as NSURL])
        }
        if showToastFeedback {
            showToast(id: id, text: "Copied ✓")
        }
    }

    /// Copies a 1x (logical resolution) version of the screenshot to the clipboard.
    public func copyDownscaled(id: UUID, showToastFeedback: Bool = true) {
        guard let item = items.first(where: { $0.id == id }) else { return }

        if ImageScaler.copyDownscaledToPasteboard(imageAt: item.url) {
            if showToastFeedback {
                showToast(id: id, text: "Copied 1x ✓")
            }
        } else if showToastFeedback {
            showToast(id: id, text: "Copy 1x Failed")
        }
    }

    /// Dispatches a card action bound to a toolbar slot or click gesture.
    public func executeAction(_ action: CardActionKind, id: UUID, grabView: Any? = nil) {
        switch action {
        case .copyDownscaled:
            copyDownscaled(id: id)
        case .copyOriginal:
            copy(id: id)
        case .copyOCR:
            copyText(id: id)
        case .saveToFolder:
            saveToLocation(id: id)
        case .saveAs:
            saveAs(id: id)
        case .pin:
            togglePin(id: id)
        case .openInPreview:
            openInDefaultApp(id: id)
        case .share:
            if let grabView = grabView as? ScreenshotGrabView {
                grabView.showShareMenu()
            }
        case .none:
            break
        }
    }

    public func copyText(id: UUID) {
        guard let item = items.first(where: { $0.id == id }) else { return }

        showToast(id: id, text: "Extracting Text...")

        Task { @MainActor in
            do {
                let text = try await TextRecognitionService.recognizeText(from: item.url)
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    self.showToast(id: id, text: "No Text Found")
                } else {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(trimmed, forType: .string)
                    self.showToast(id: id, text: "Text Copied ✓")
                }
            } catch {
                self.showToast(id: id, text: "OCR Failed")
            }
        }
    }

    public func saveAs(id: UUID) {
        guard let item = items.first(where: { $0.id == id }) else { return }

        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = true
        savePanel.directoryURL = OsokoSettings.shared.saveLocationURL

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' h.mm.ss a"
        let timestamp = formatter.string(from: item.createdAt)
        savePanel.nameFieldStringValue = "Screenshot \(timestamp).png"

        NSApp.activate(ignoringOtherApps: true)
        let response = savePanel.runModal()

        guard response == .OK, let destination = savePanel.url else { return }

        ExportTracker.shared.register(url: destination)
        ExportTracker.shared.register(url: destination.resolvingSymlinksInPath())

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: item.url, to: destination)

            destination.withUnsafeFileSystemRepresentation { p in
                guard let p else { return }
                removexattr(p, "com.apple.metadata:kMDItemIsScreenCapture", 0)
                let val = "1"
                setxattr(p, "com.osoko.saved", val, val.utf8.count, 0, 0)
            }

            let fileName = destination.lastPathComponent
            showToast(id: id, text: "Saved as \(fileName) ✓")
        } catch {
            showToast(id: id, text: "Save Failed")
        }
    }

    public func saveToLocation(id: UUID) {
        if OsokoSettings.shared.promptToRenameOnSave {
            saveAs(id: id)
            return
        }

        guard let item = items.first(where: { $0.id == id }) else { return }
        let targetDir = OsokoSettings.shared.saveLocationURL.resolvingSymlinksInPath()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' h.mm.ss a"
        let timestamp = formatter.string(from: item.createdAt)
        let destination = uniqueURL(in: targetDir, baseName: "Screenshot \(timestamp)", ext: "png")

        // Pre-register both raw and resolved paths so watchers ignore this exported file
        ExportTracker.shared.register(url: destination)
        ExportTracker.shared.register(url: destination.resolvingSymlinksInPath())

        do {
            try FileManager.default.copyItem(at: item.url, to: destination)

            // Remove macOS screenshot attribute and mark with Osoko saved tag
            destination.withUnsafeFileSystemRepresentation { p in
                guard let p else { return }
                removexattr(p, "com.apple.metadata:kMDItemIsScreenCapture", 0)
                let val = "1"
                setxattr(p, "com.osoko.saved", val, val.utf8.count, 0, 0)
            }

            let folderName = targetDir.lastPathComponent
            let message = folderName.lowercased() == "desktop" ? "Saved to Desktop ✓" : "Saved to \(folderName) ✓"
            showToast(id: id, text: message)
        } catch {
            showToast(id: id, text: "Save Failed")
        }
    }

    private func uniqueURL(in directory: URL, baseName: String, ext: String) -> URL {
        var candidate = directory.appendingPathComponent("\(baseName).\(ext)")
        var counter = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(baseName) (\(counter)).\(ext)")
            counter += 1
        }
        return candidate
    }

    public func openInDefaultApp(id: UUID) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        NSWorkspace.shared.open(item.url)
    }

    public func revealInFinder(id: UUID) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }

    public func clearAll() {
        for item in items where !item.isPinned {
            TextRecognitionService.clearCache(for: item.url)
            try? FileManager.default.removeItem(at: item.url)
        }
        items.removeAll(where: { !$0.isPinned })
        if items.isEmpty {
            StackCollapseState.shared.stopEdgeMonitoring()
        }
    }

    private func showToast(id: UUID, text: String) {
        toastMessage = (id, text)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            if self.toastMessage?.id == id {
                self.toastMessage = nil
            }
        }
    }
}
