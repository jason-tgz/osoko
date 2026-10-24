import SwiftUI

public struct ScreenshotStackView: View {
    @ObservedObject var stack: ScreenshotStack
    @ObservedObject var visibility = StackCollapseState.shared

    public init(stack: ScreenshotStack = .shared) {
        self.stack = stack
    }

    public var body: some View {
        ZStack(alignment: .trailing) {
            // Main Cards Stack
            VStack(alignment: .trailing, spacing: 10) {
                Spacer(minLength: 0)

                ForEach(stack.items) { item in
                    ScreenshotCardView(item: item, stack: stack)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.85).combined(with: .opacity).combined(with: .offset(y: 15)),
                                removal: .scale(scale: 0.7).combined(with: .opacity)
                            )
                        )
                }

                if !stack.items.isEmpty {
                    // Floating stack toolbar
                    HStack(spacing: 8) {
                        Button(action: {
                            ScreenshotCaptureService.shared.captureInteractive()
                        }) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        .help("Take new screenshot (⌘⇧S)")

                        if stack.items.count >= 2 {
                            Button(action: {
                                stack.clearAll()
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.plain)
                            .help("Clear unpinned screenshots")
                        }

                        Button(action: {
                            SettingsWindowController.shared.show()
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        .help("Osoko Settings")

                        // Collapse to side button
                        Button(action: {
                            visibility.collapse()
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 20, height: 24)
                        }
                        .buttonStyle(.plain)
                        .help("Slide into screen edge")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 2)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .offset(x: visibility.isCollapsed ? 320 : 0)
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: visibility.isCollapsed)
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: stack.items.map(\.id))
            .onHover { isHovering in
                visibility.userHoverChanged(isHovering: isHovering)
            }

            // Peeking edge handle when collapsed to the side
            if visibility.isCollapsed && !stack.items.isEmpty {
                Button(action: {
                    visibility.expand()
                }) {
                    Capsule()
                        .fill(Color.white.opacity(0.45))
                        .frame(width: 4, height: 44)
                        .shadow(color: Color.black.opacity(0.25), radius: 4)
                        .padding(.trailing, 2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Click or move cursor to bottom edge of screen to expand stack")
                .onHover { isHovering in
                    if isHovering {
                        visibility.expand()
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }
}
