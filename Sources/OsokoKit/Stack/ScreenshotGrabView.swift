import AppKit
import SwiftUI

public enum ScreenshotButtonKind: Sendable, Equatable {
    case close
    case action(CardActionKind)
}

private func isWebLink(_ payload: String) -> Bool {
    guard let url = URL(string: payload) else { return false }
    let scheme = url.scheme?.lowercased()
    return scheme == "http" || scheme == "https"
}

struct ScreenshotGrabArea: NSViewRepresentable {
    let item: ScreenshotItem
    let stack: ScreenshotStack
    let topActions: [CardActionKind]
    let bottomActions: [CardActionKind]

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
        view.detectedBarcode = item.detectedBarcode
        view.topActions = topActions
        view.bottomActions = bottomActions
        view.onClick = {
            stack.executeAction(OsokoSettings.shared.primaryClickAction, id: id)
        }
        view.onDoubleClick = {
            stack.executeAction(OsokoSettings.shared.doubleClickAction, id: id)
        }
        view.onAction = { [weak view] action in
            guard let view else { return }
            stack.executeAction(action, id: id, grabView: view)
        }
        view.onDropIntoApp = { stack.consumeDrop(id: id) }
        view.onRemove = { stack.remove(id: id) }
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
            menu.addItem(NSMenuItem(title: "Copy 1x Downscaled", action: #selector(ScreenshotGrabView.menuCopyDownscaled), keyEquivalent: "1"))
            menu.addItem(NSMenuItem(title: "Copy Text (OCR)", action: #selector(ScreenshotGrabView.menuOCR), keyEquivalent: "t"))
            menu.addItem(NSMenuItem(title: "Redact Sensitive Data", action: #selector(ScreenshotGrabView.menuRedact), keyEquivalent: "r"))
            if let barcode = item.detectedBarcode, !barcode.isEmpty {
                if isWebLink(barcode) {
                    menu.addItem(NSMenuItem(title: "Open QR Code Link", action: #selector(ScreenshotGrabView.menuOpenQRLink), keyEquivalent: "l"))
                }
                menu.addItem(NSMenuItem(title: "Copy QR Code Link", action: #selector(ScreenshotGrabView.menuCopyQRLink), keyEquivalent: ""))
            }
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "Save to Location", action: #selector(ScreenshotGrabView.menuSave), keyEquivalent: "s"))
            let saveAsItem = NSMenuItem(title: "Save As... (Rename)", action: #selector(ScreenshotGrabView.menuSaveAs), keyEquivalent: "S")
            menu.addItem(saveAsItem)
            menu.addItem(NSMenuItem(title: "Share...", action: #selector(ScreenshotGrabView.menuShare), keyEquivalent: ""))
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
        view.window?.invalidateCursorRects(for: view)
    }
}

final class ScreenshotGrabView: NSView, NSDraggingSource {
    override var isFlipped: Bool { true }

    var url: URL?
    var dragImage: NSImage?
    var isPinned: Bool = false
    var detectedBarcode: String?
    var topActions: [CardActionKind] = []
    var bottomActions: [CardActionKind] = []

    var onClick: () -> Void = {}
    var onDoubleClick: () -> Void = {}
    var onAction: (CardActionKind) -> Void = { _ in }
    var onDropIntoApp: () -> Void = {}
    var onRemove: () -> Void = {}
    var onReveal: () -> Void = {}
    var onClearStack: () -> Void = {}
    var onOpenSettings: () -> Void = {}
    var onQuitApp: () -> Void = {}
    var menuProvider: () -> NSMenu = { NSMenu() }

    private var downPoint: NSPoint?
    private var startedDrag = false
    private var hoverTrackingArea: NSTrackingArea?
    private var isMouseInside = false
    private var keyMonitor: Any?

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // MARK: - Hover Tracking

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let hoverTrackingArea {
            removeTrackingArea(hoverTrackingArea)
        }

        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        hoverTrackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        isMouseInside = true
        if OsokoSettings.shared.enableHoverShortcuts {
            window?.makeKey()
            window?.makeFirstResponder(self)
            startKeyMonitor()
        }
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        isMouseInside = false
        stopKeyMonitor()
        if window?.firstResponder === self {
            window?.makeFirstResponder(nil)
        }
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        if newWindow == nil {
            stopKeyMonitor()
        }
    }

    private func startKeyMonitor() {
        guard keyMonitor == nil else { return }

        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleShortcut(event: event)
            }
        }
    }

    private func stopKeyMonitor() {
        guard let keyMonitor else { return }
        NSEvent.removeMonitor(keyMonitor)
        self.keyMonitor = nil
    }

    // MARK: - Hit Testing

    func actionZone(at p: NSPoint) -> ScreenshotButtonKind? {
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return nil }

        // Top-left: Close button (x: 0...36, y: 0...34)
        if closeButtonRect.contains(p) {
            return .close
        }

        // Top-right: configured action slots, ordered slot 1 then slot 2.
        if let action = action(at: p, in: topActions, width: w, height: h, isTop: true) {
            return .action(action)
        }

        // Bottom-right: configured action slots, ordered slot 1 then slot 2.
        if let action = action(at: p, in: bottomActions, width: w, height: h, isTop: false) {
            return .action(action)
        }

        return nil
    }

    private var closeButtonRect: NSRect {
        NSRect(x: 0, y: 0, width: 36, height: 34)
    }

    private func actionRects(in actions: [CardActionKind], width w: CGFloat, height h: CGFloat, isTop: Bool) -> [(CardActionKind, NSRect)] {
        let active = actions.filter { $0 != .none }
        guard !active.isEmpty else { return [] }

        let y = isTop ? 0 : max(0, h - 34)
        let count = CGFloat(active.count)

        return active.enumerated().map { index, action in
            let rightEdge = w - 34 * (count - CGFloat(index) - 1)
            let rect = NSRect(x: rightEdge - 34, y: y, width: 34, height: 34)
            return (action, rect)
        }
    }

    private func action(
        at p: NSPoint,
        in actions: [CardActionKind],
        width w: CGFloat,
        height h: CGFloat,
        isTop: Bool
    ) -> CardActionKind? {
        actionRects(in: actions, width: w, height: h, isTop: isTop)
            .first(where: { $0.1.contains(p) })?
            .0
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }

        addCursorRect(closeButtonRect, cursor: .pointingHand)
        for (_, rect) in actionRects(in: topActions, width: w, height: h, isTop: true) {
            addCursorRect(rect, cursor: .pointingHand)
        }
        for (_, rect) in actionRects(in: bottomActions, width: w, height: h, isTop: false) {
            addCursorRect(rect, cursor: .pointingHand)
        }
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        if let zone = actionZone(at: p) {
            downPoint = nil
            startedDrag = false
            switch zone {
            case .close:
                onRemove()
            case .action(let action):
                onAction(action)
            }
            return
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

    // MARK: - Keyboard Shortcuts

    override func keyDown(with event: NSEvent) {
        guard isMouseInside,
              OsokoSettings.shared.enableHoverShortcuts,
              !event.modifierFlags.contains(.command) else {
            super.keyDown(with: event)
            return
        }

        handleShortcut(event: event)
    }

    private func handleShortcut(event: NSEvent) {
        guard OsokoSettings.shared.enableHoverShortcuts else { return }
        guard !event.modifierFlags.contains(.command) else { return }

        // The global monitor fires while another application is focused, so make
        // sure the pointer is actually over this specific card before acting.
        let mouseLocation = NSEvent.mouseLocation
        guard let window = self.window else { return }
        let windowPoint = window.convertPoint(fromScreen: mouseLocation)
        let viewPoint = self.convert(windowPoint, from: nil)
        guard self.bounds.contains(viewPoint) else { return }

        let key = (event.charactersIgnoringModifiers ?? "").lowercased()
        switch key {
        case "1":
            onAction(.copyDownscaled)
        case "2", "c":
            onAction(.copyOriginal)
        case "t":
            onAction(.copyOCR)
        case "r":
            onAction(.redactSensitive)
        case "l":
            if let barcode = detectedBarcode,
               !barcode.isEmpty,
               isWebLink(barcode) {
                onAction(.openQRLink)
            } else {
                onAction(.copyQRLink)
            }
        case "s":
            if event.modifierFlags.contains(.shift) || event.modifierFlags.contains(.option) {
                onAction(.saveAs)
            } else {
                onAction(.saveToFolder)
            }
        case "p":
            onAction(.pin)
        case " ":
            onAction(.openInPreview)
        case "\u{7f}", "\u{08}":
            onRemove()
        default:
            break
        }
    }

    // MARK: - Menu Actions

    @objc func menuCopy() { onAction(.copyOriginal) }
    @objc func menuCopyDownscaled() { onAction(.copyDownscaled) }
    @objc func menuOCR() { onAction(.copyOCR) }
    @objc func menuRedact() { onAction(.redactSensitive) }
    @objc func menuCopyQRLink() { onAction(.copyQRLink) }
    @objc func menuOpenQRLink() { onAction(.openQRLink) }
    @objc func menuSave() { onAction(.saveToFolder) }
    @objc func menuSaveAs() { onAction(.saveAs) }
    @objc func menuShare() { onAction(.share) }
    @objc func menuTogglePin() { onAction(.pin) }
    @objc func menuOpen() { onAction(.openInPreview) }
    @objc func menuReveal() { onReveal() }
    @objc func menuDelete() { onRemove() }
    @objc func menuSettings() { onOpenSettings() }
    @objc func menuClearStack() { onClearStack() }
    @objc func menuQuit() { onQuitApp() }

    public func showShareMenu() {
        guard let url else { return }
        let picker = NSSharingServicePicker(items: [url])
        let targetRect = NSRect(x: bounds.width - 34, y: max(0, bounds.height - 34), width: 34, height: 34)
        picker.show(relativeTo: targetRect, of: self, preferredEdge: .maxY)
    }

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
