import AppKit
import Foundation

@MainActor
public final class ScreenshotStack: ObservableObject {
    public static let shared = ScreenshotStack()

    @Published public private(set) var items: [ScreenshotItem] = []
    @Published public var toastMessage: (id: UUID, text: String)?

    nonisolated public static let storageDirectory: URL = {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("OsokoScreenshots", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    public init() {
        Self.cleanupOldTemporaryFiles()
    }

    @discardableResult
    public func add(fileURL: URL) -> ScreenshotItem? {
        // Prevent duplicate items for the same file path
        if let existing = items.first(where: { $0.url.path == fileURL.path }) {
            return existing
        }

        guard let image = NSImage(contentsOf: fileURL) else { return nil }
        let rep = image.representations.first
        let width = rep?.pixelsWide ?? Int(image.size.width)
        let height = rep?.pixelsHigh ?? Int(image.size.height)
        guard width > 0, height > 0 else { return nil }

        let item = ScreenshotItem(
            url: fileURL,
            thumbnail: image,
            pixelWidth: max(1, width),
            pixelHeight: max(1, height)
        )

        // Newest capture enters top of stack
        items.insert(item, at: 0)

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

        return item
    }

    public func remove(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let item = items.remove(at: index)
        try? FileManager.default.removeItem(at: item.url)
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

    public func saveToLocation(id: UUID) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        let targetDir = OsokoSettings.shared.saveLocationURL
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' h.mm.ss a"
        let timestamp = formatter.string(from: item.createdAt)
        let destination = targetDir.appendingPathComponent("Screenshot \(timestamp).png")

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: item.url, to: destination)
            showToast(id: id, text: "Saved ✓")
        } catch {
            showToast(id: id, text: "Save Failed")
        }
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
            try? FileManager.default.removeItem(at: item.url)
        }
        items.removeAll(where: { !$0.isPinned })
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
