import AppKit
import SwiftUI

/// Two opposing capture corners form an open “o”. Coordinates use a 64-point grid.
enum OsokoBrand {
    static func markPath(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 36, y: 12))
        path.addLine(to: CGPoint(x: 26, y: 12))
        path.addCurve(to: CGPoint(x: 12, y: 26), control1: CGPoint(x: 16, y: 12), control2: CGPoint(x: 12, y: 16))
        path.addLine(to: CGPoint(x: 12, y: 40))
        path.move(to: CGPoint(x: 28, y: 52))
        path.addLine(to: CGPoint(x: 38, y: 52))
        path.addCurve(to: CGPoint(x: 52, y: 38), control1: CGPoint(x: 48, y: 52), control2: CGPoint(x: 52, y: 48))
        path.addLine(to: CGPoint(x: 52, y: 24))
        let outline = path.copy(strokingWithWidth: 9, lineCap: .round, lineJoin: .round, miterLimit: 1)
        let scale = min(rect.width, rect.height) / 64
        var transform = CGAffineTransform(translationX: rect.midX - 32 * scale, y: rect.midY - 32 * scale)
            .scaledBy(x: scale, y: scale)
        return outline.copy(using: &transform) ?? outline
    }

    @MainActor static var menuBarImage: NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.addPath(markPath(in: rect))
            context.setFillColor(NSColor.black.cgColor)
            context.fillPath()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Osoko"
        return image
    }
}

struct OsokoMark: Shape {
    func path(in rect: CGRect) -> Path {
        Path(OsokoBrand.markPath(in: rect))
    }
}

struct OsokoAppIcon: View {
    var body: some View {
        OsokoMark()
            .fill(Color(red: 0.10, green: 0.11, blue: 0.10))
            .padding(8)
            .background(Color(red: 0.96, green: 0.95, blue: 0.92), in: RoundedRectangle(cornerRadius: 16))
            .accessibilityLabel("Osoko")
    }
}
