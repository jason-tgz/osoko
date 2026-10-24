import AppKit
import SwiftUI

public enum ScreenshotButtonKind: Sendable, Equatable {
    case close
    case save
    case pin
}

struct ScreenshotGrabArea: NSViewRepresentable {
    let item: ScreenshotItem
    let stack: ScreenshotStack

    func makeNSView(context: Context) -> ScreenshotGrabView {
        let view = ScreenshotGrabView()
        configure(view)
        return view
    }

    func updateNSView(_ view: ScreenshotGrabView, context: Context) {
        configure(view)
    }

    private func configure(_ view: ScreenshotGrabView) {
        let id = item.id
        let stack = stack
        view.url = item.url
        view.dragImage = item.thumbnail
        view.isPinned = item.isPinned
        view.onClick = { stack.copy(id: id) }
        view.onDoubleClick = { stack.openInDefaultApp(id: id) }
        view.onDropIntoApp = { stack.consumeDrop(id: id) }
        view.onRemove = { stack.remove(id: id) }
        view.onSaveToDesktop = { stack.saveToLocation(id: id) }
        view.onTogglePin = { stack.togglePin(id: id) }
        view.onReveal = { stack.revealInFinder(id: id) }
        view.onClearStack = { stack.clearAll() }
        view.onOpenSettings = {
            SettingsWindowController.shared.show()
        }
        view.onQuitApp = {
            NSApp.terminate(nil)
        }
        view.menuProvider = {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Copy Image", action: #selector(ScreenshotGrabView.menuCopy), keyEquivalent: "c"))
            menu.addItem(NSMenuItem(title: "Save to Location", action: #selector(ScreenshotGrabView.menuSave), keyEquivalent: "s"))
            menu.addItem(.separator())
            let pinTitle = item.isPinned ? "Unpin from Stack" : "Keep on Stack"
            let pinItem = NSMenuItem(title: pinTitle, action: #selector(ScreenshotGrabView.menuTogglePin), keyEquivalent: "p")
            menu.addItem(pinItem)
            menu.addItem(NSMenuItem(title: "Open in Preview", action: #selector(ScreenshotGrabView.menuOpen), keyEquivalent: "o"))
            menu.addItem(NSMenuItem(title: "Reveal in Finder", action: #selector(ScreenshotGrabView.menuReveal), keyEquivalent: "r"))
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "Delete", action: #selector(ScreenshotGrabView.menuDelete), keyEquivalent: ""))
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "Settings...", action: #selector(ScreenshotGrabView.menuSettings), keyEquivalent: ","))
            menu.addItem(NSMenuItem(title: "Clear Stack", action: #selector(ScreenshotGrabView.menuClearStack), keyEquivalent: ""))
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "Quit Osoko", action: #selector(ScreenshotGrabView.menuQuit), keyEquivalent: "q"))
            return menu
        }
    }
}

final class ScreenshotGrabView: NSView, NSDraggingSource {
    override var isFlipped: Bool { true }

    var url: URL?
    var dragImage: NSImage?
    var isPinned: Bool = false
    var onClick: () -> Void = {}
    var onDoubleClick: () -> Void = {}
    var onDropIntoApp: () -> Void = {}
    var onRemove: () -> Void = {}
    var onSaveToDesktop: () -> Void = {}
    var onTogglePin: () -> Void = {}
    var onReveal: () -> Void = {}
    var onClearStack: () -> Void = {}
    var onOpenSettings: () -> Void = {}
    var onQuitApp: () -> Void = {}
    var menuProvider: () -> NSMenu = { NSMenu() }

    private var downPoint: NSPoint?
    private var startedDrag = false

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    func actionZone(at p: NSPoint) -> ScreenshotButtonKind? {
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return nil }

        // Top-left: Close button (x: 0...36, y: 0...34)
        if NSRect(x: 0, y: 0, width: 36, height: 34).contains(p) {
            return .close
        }

        // Top-right: Pin button (x: w - 34...w, y: 0...34)
        if NSRect(x: w - 34, y: 0, width: 34, height: 34).contains(p) {
            return .pin
        }

        // Top-right: Save button (x: w - 68...w - 34, y: 0...34)
        if NSRect(x: w - 68, y: 0, width: 34, height: 34).contains(p) {
            return .save
        }

        return nil
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }

        addCursorRect(NSRect(x: 0, y: 0, width: 36, height: 34), cursor: .pointingHand)
        addCursorRect(NSRect(x: w - 68, y: 0, width: 34, height: 34), cursor: .pointingHand)
        addCursorRect(NSRect(x: w - 34, y: 0, width: 34, height: 34), cursor: .pointingHand)
    }

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        if let zone = actionZone(at: p) {
            downPoint = nil
            startedDrag = false
            switch zone {
            case .close:
                onRemove()
                return
            case .save:
                onSaveToDesktop()
                return
            case .pin:
                onTogglePin()
                return
            }
        }

        if event.clickCount == 2 {
            downPoint = nil
            startedDrag = false
            onDoubleClick()
            return
        }

        downPoint = event.locationInWindow
        startedDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = downPoint, !startedDrag, let url else { return }
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let p = event.locationInWindow
        guard hypot(p.x - start.x, p.y - start.y) > 4 else { return }
        startedDrag = true

        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(url.absoluteString, forType: .fileURL)
        if let data = try? Data(contentsOf: url), !data.isEmpty {
            pasteboardItem.setData(data, forType: .png)
        } else if let tiff = dragImage?.tiffRepresentation {
            pasteboardItem.setData(tiff, forType: .tiff)
        }

        let dragItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        dragItem.setDraggingFrame(imageFrame(), contents: dragImage)
        let session = beginDraggingSession(with: [dragItem], event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
    }

    override func mouseUp(with event: NSEvent) {
        if downPoint != nil && !startedDrag && event.clickCount == 1 {
            onClick()
        }
        downPoint = nil
        startedDrag = false
    }

    override func rightMouseDown(with event: NSEvent) {
        let menu = menuProvider()
        for item in menu.items { item.target = self }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc func menuCopy() { onClick() }
    @objc func menuSave() { onSaveToDesktop() }
    @objc func menuTogglePin() { onTogglePin() }
    @objc func menuOpen() { onDoubleClick() }
    @objc func menuReveal() { onReveal() }
    @objc func menuDelete() { onRemove() }
    @objc func menuSettings() { onOpenSettings() }
    @objc func menuClearStack() { onClearStack() }
    @objc func menuQuit() { onQuitApp() }

    // MARK: - NSDraggingSource
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        context == .outsideApplication ? [.copy, .move, .delete] : [.copy, .generic]
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        startedDrag = false
        downPoint = nil
        if operation.contains(.delete) {
            onRemove()
            return
        }
        if operation.contains(.copy) || operation.contains(.move) {
            onDropIntoApp()
        }
    }

    private func imageFrame() -> NSRect {
        guard let size = dragImage?.size, size.width > 0, size.height > 0 else { return bounds }
        let scale = min(bounds.width / size.width, bounds.height / size.height)
        let w = size.width * scale, h = size.height * scale
        return NSRect(x: (bounds.width - w) / 2, y: (bounds.height - h) / 2, width: w, height: h)
    }
}
