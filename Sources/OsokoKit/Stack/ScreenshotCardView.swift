import SwiftUI

struct ScreenshotCardView: View {
    let item: ScreenshotItem
    @ObservedObject var stack: ScreenshotStack
    @ObservedObject private var settings = OsokoSettings.shared

    @State private var isHovering = false

    private let maxCardWidth: CGFloat = 185
    private let minCardHeight: CGFloat = 65
    private let maxCardHeight: CGFloat = 140

    private var cardSize: CGSize {
        let w = maxCardWidth
        let ratio = max(0.3, min(2.5, item.aspectRatio))
        let h = min(maxCardHeight, max(minCardHeight, w / ratio))
        return CGSize(width: w, height: h)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
    }

    private var topActions: [CardActionKind] {
        [settings.topActionSlot1, settings.topActionSlot2].filter { $0 != .none }
    }

    private var bottomActions: [CardActionKind] {
        [settings.bottomActionSlot1, settings.bottomActionSlot2].filter { $0 != .none }
    }

    var body: some View {
        ZStack {
            // 1. Thumbnail Image
            Image(nsImage: item.thumbnail)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fill)
                .frame(width: cardSize.width, height: cardSize.height)
                .clipShape(shape)

            // 2. Specular glass border
            shape
                .strokeBorder(Color.white.opacity(0.38), lineWidth: 0.8)
            shape
                .stroke(Color.black.opacity(0.18), lineWidth: 0.5)
                .padding(-0.5)

            // 3. Detected QR / Barcode Indicator
            if let barcode = item.detectedBarcode, !barcode.isEmpty {
                VStack {
                    qrBadge(for: barcode)
                        .padding(.top, isHovering ? 36 : 6)
                    Spacer()
                }
                .frame(width: cardSize.width, height: cardSize.height, alignment: .top)
                .allowsHitTesting(false)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // 4. Hover Overlay Controls
            if isHovering {
                VStack {
                    HStack(spacing: 6) {
                        // Close / Delete Button (Top-Left)
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 22, height: 22)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 0.5))
                            .help("Remove from stack")

                        Spacer()

                        // Configurable Top-Right Action Slots (slot 1 then slot 2)
                        ForEach(Array(topActions.enumerated()), id: \.offset) { _, action in
                            actionButton(action)
                        }
                    }
                    .padding(5)

                    Spacer()

                    // Bottom Row: Dimensions Badge & Configurable Action Slots
                    HStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Text(item.formattedDimensions)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.5))

                        Spacer()

                        // Configurable Bottom-Right Action Slots (slot 1 then slot 2)
                        ForEach(Array(bottomActions.enumerated()), id: \.offset) { _, action in
                            actionButton(action)
                        }
                    }
                    .padding(5)
                }
                .allowsHitTesting(false)
            } else if item.isPinned {
                // If pinned and not hovering, keep subtle pin indicator
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.orange)
                            .frame(width: 18, height: 18)
                            .background(.ultraThinMaterial, in: Circle())
                            .padding(4)
                    }
                    Spacer()
                }
                .allowsHitTesting(false)
            }

            // 5. Toast Badge Feedback ("Copied ✓" / "Saved ✓" / "Pinned 📌")
            if let toast = stack.toastMessage, toast.id == item.id {
                Text(toast.text)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.80), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .allowsHitTesting(false)
            }

            // 6. Native AppKit Drag & Drop and Click Handling Area
            ScreenshotGrabArea(
                item: item,
                stack: stack,
                topActions: topActions,
                bottomActions: bottomActions
            )
            .frame(width: cardSize.width, height: cardSize.height)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(shape)
        .shadow(
            color: Color.black.opacity(isHovering ? 0.35 : 0.22),
            radius: isHovering ? 12 : 7,
            x: 0,
            y: isHovering ? 5 : 3
        )
        .scaleEffect(isHovering ? 1.025 : 1.0)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isHovering)
        .animation(.easeOut(duration: 0.2), value: stack.toastMessage?.text)
        .animation(.easeOut(duration: 0.2), value: item.detectedBarcode)
        .onHover { isHovering = $0 }
    }

    private func qrBadge(for payload: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "qrcode")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color.green)

            Text("QR: \(barcodeDisplayText(payload))")
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2.5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.green.opacity(0.35), lineWidth: 0.5))
        .frame(maxWidth: 132)
        .shadow(color: Color.black.opacity(0.18), radius: 3, x: 0, y: 1)
    }

    private func barcodeDisplayText(_ payload: String) -> String {
        if let url = URL(string: payload), let host = url.host, !host.isEmpty {
            return host
        }
        return payload
    }

    @ViewBuilder
    private func actionButton(_ action: CardActionKind) -> some View {
        let pinned = action == .pin && item.isPinned

        Image(systemName: pinned ? "pin.fill" : action.iconName)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(pinned ? Color.orange : Color.primary)
            .frame(width: 22, height: 22)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 0.5))
            .help(action.tooltip)
    }
}
