import AppKit
import SwiftUI
import Combine

@MainActor
public final class ScreenshotStackPanel: NSPanel {
    public static let shared = ScreenshotStackPanel()

    private let stack: ScreenshotStack
    private var cancellables: Set<AnyCancellable> = []

    public init(stack: ScreenshotStack = .shared) {
        self.stack = stack
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 230, height: 420),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        sharingType = .readOnly // Temporarily set to .readOnly for demo screen recording (default was .none)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hidesOnDeactivate = false
        isMovable = false
        becomesKeyOnlyIfNeeded = true

        contentView = NSHostingView(rootView: ScreenshotStackView(stack: stack))

        observeStack()
    }

    override public var canBecomeKey: Bool { false }
    override public var canBecomeMain: Bool { false }

    private func observeStack() {
        stack.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.reposition(itemCount: items.count)
            }
            .store(in: &cancellables)
    }

    public func reposition(itemCount: Int) {
        guard itemCount > 0 else {
            orderOut(nil)
            StackCollapseState.shared.stopEdgeMonitoring()
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSPointInRect(mouseLocation, $0.frame) })
            ?? NSScreen.main
            ?? NSScreen.screens.first

        let visibleFrame = screen?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let screenFrame = screen?.frame ?? visibleFrame

        let panelWidth: CGFloat = 225
        let cardEstimateHeight: CGFloat = 130
        let toolbarHeight: CGFloat = 45
        let panelHeight = min(visibleFrame.height - 40, CGFloat(itemCount) * cardEstimateHeight + toolbarHeight + 20)

        let x = visibleFrame.maxX - panelWidth - 10
        let y = visibleFrame.minY + 10
        let windowWidth = max(panelWidth + 10, screenFrame.maxX - x)

        setFrame(NSRect(x: x, y: y, width: windowWidth, height: panelHeight), display: true)
        orderFrontRegardless()
    }
}
