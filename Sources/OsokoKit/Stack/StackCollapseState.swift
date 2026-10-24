import AppKit
import SwiftUI
import Foundation
import Combine

@MainActor
public final class StackCollapseState: ObservableObject {
    public static let shared = StackCollapseState()

    @Published public var isCollapsed: Bool = false
    @Published public var isHovering: Bool = false

    private var collapseWorkItem: DispatchWorkItem?
    private var edgeMonitorTimer: Timer?
    private var globalMouseMonitor: Any?

    private init() {}

    /// Called when a new screenshot is added to the stack.
    public func onNewScreenshotAdded() {
        expand()
        resetCollapseTimer()
    }

    /// Expands the stack so all cards are visible.
    public func expand() {
        if isCollapsed {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isCollapsed = false
            }
        }
        stopEdgeMonitoring()
        if !isHovering {
            resetCollapseTimer()
        }
    }

    /// Collapses the stack into the side of the screen.
    public func collapse() {
        guard !isHovering else { return }
        guard OsokoSettings.shared.autoCollapseEnabled else { return }

        cancelCollapseTimer()
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            isCollapsed = true
        }
        startEdgeMonitoring()
    }

    /// Tracks whether the user is currently hovering over the stack cards or toolbar.
    public func userHoverChanged(isHovering: Bool) {
        self.isHovering = isHovering

        if isHovering {
            // User is interacting: cancel pending auto-collapse
            cancelCollapseTimer()
            if isCollapsed {
                expand()
            }
        } else {
            // User left the stack: start the auto-collapse countdown
            if !isCollapsed {
                resetCollapseTimer()
            }
        }
    }

    /// Starts or resets the 10-second auto-collapse countdown.
    public func resetCollapseTimer() {
        cancelCollapseTimer()
        guard OsokoSettings.shared.autoCollapseEnabled else { return }
        guard !isHovering else { return }

        let delay = max(2.0, OsokoSettings.shared.autoCollapseDelay)
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if !self.isHovering && !self.isCollapsed && !ScreenshotStack.shared.items.isEmpty {
                    self.collapse()
                }
            }
        }
        self.collapseWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    public func cancelCollapseTimer() {
        collapseWorkItem?.cancel()
        collapseWorkItem = nil
    }

    // MARK: - Edge Detection (Bottom edge / corner)
    public func startEdgeMonitoring() {
        stopEdgeMonitoring()

        // 1. Lightweight 12Hz timer to inspect mouse location with zero permissions
        edgeMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkMousePosition()
            }
        }

        // 2. Also register global mouse monitor if permitted for instant response
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkMousePosition()
            }
        }
    }

    public func stopEdgeMonitoring() {
        edgeMonitorTimer?.invalidate()
        edgeMonitorTimer = nil

        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
    }

    private func checkMousePosition() {
        guard isCollapsed, !ScreenshotStack.shared.items.isEmpty else {
            stopEdgeMonitoring()
            return
        }

        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSPointInRect(mouse, $0.frame) })
            ?? NSScreen.main
            ?? NSScreen.screens.first

        guard let screen else { return }
        let visibleFrame = screen.visibleFrame
        let screenFrame = screen.frame

        // Tight edge threshold: only activate when the cursor is right against the screen border (within 3 points)
        let edgeThreshold: CGFloat = 3.0

        // 1. Bottom edge: cursor must touch the bottom border (within 3 points) on the right half of the display
        let isAtBottomEdge = (mouse.y <= visibleFrame.minY + edgeThreshold || mouse.y <= screenFrame.minY + edgeThreshold)
            && (mouse.x >= visibleFrame.midX)

        // 2. Right edge: cursor must touch the right border (within 3 points) in the lower section of the display
        let isAtRightEdge = (mouse.x >= visibleFrame.maxX - edgeThreshold || mouse.x >= screenFrame.maxX - edgeThreshold)
            && (mouse.y <= visibleFrame.minY + 300)

        if isAtBottomEdge || isAtRightEdge {
            expand()
        }
    }
}
