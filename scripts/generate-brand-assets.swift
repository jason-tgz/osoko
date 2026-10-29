// Run from the repository root:
// swiftc Sources/OsokoKit/App/OsokoBrand.swift scripts/generate-brand-assets.swift -o /tmp/osoko-brand && /tmp/osoko-brand
import AppKit
import CoreText

@main
struct GenerateBrandAssets {
    static let ink = NSColor(srgbRed: 0.10, green: 0.11, blue: 0.10, alpha: 1).cgColor
    static let paper = NSColor(srgbRed: 0.96, green: 0.95, blue: 0.92, alpha: 1).cgColor

    static func svgPath(_ path: CGPath) -> String {
        var result = ""
        func point(_ p: CGPoint) -> String { String(format: "%.3f %.3f", p.x, p.y) }
        path.applyWithBlock { pointer in
            let element = pointer.pointee
            switch element.type {
            case .moveToPoint: result += "M\(point(element.points[0])) "
            case .addLineToPoint: result += "L\(point(element.points[0])) "
            case .addQuadCurveToPoint: result += "Q\(point(element.points[0])) \(point(element.points[1])) "
            case .addCurveToPoint: result += "C\(point(element.points[0])) \(point(element.points[1])) \(point(element.points[2])) "
            case .closeSubpath: result += "Z "
            @unknown default: break
            }
        }
        return result
    }

    static func writeSVG(_ path: CGPath, size: CGSize, name: String, color: String) throws {
        let source = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(size.width) \(size.height)" role="img" aria-label="Osoko">
          <path fill="\(color)" d="\(svgPath(path))"/>
        </svg>
        """
        try source.write(toFile: "assets/\(name).svg", atomically: true, encoding: .utf8)
    }

    static func png(size: CGSize, scale: CGFloat = 1, file: String, draw: (CGContext) -> Void) throws {
        let width = Int(size.width * scale), height = Int(size.height * scale)
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
            let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else {
            throw CocoaError(.fileWriteUnknown)
        }
        let context = graphics.cgContext
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: scale, y: -scale)
        draw(context)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: URL(fileURLWithPath: file))
    }

    static func fill(_ context: CGContext, _ path: CGPath, color: CGColor) {
        context.addPath(path)
        context.setFillColor(color)
        context.fillPath()
    }

    static func wordmark() -> CGPath {
        let font = NSFont.systemFont(ofSize: 120, weight: .semibold)
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: "osoko", attributes: [.font: font, .kern: -2]))
        let path = CGMutablePath()
        for run in CTLineGetGlyphRuns(line) as! [CTRun] {
            let runFont = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName] as! CTFont
            for index in 0..<CTRunGetGlyphCount(run) {
                var glyph = CGGlyph(), position = CGPoint.zero
                CTRunGetGlyphs(run, CFRange(location: index, length: 1), &glyph)
                CTRunGetPositions(run, CFRange(location: index, length: 1), &position)
                if let outline = CTFontCreatePathForGlyph(runFont, glyph, nil) {
                    path.addPath(outline, transform: CGAffineTransform(translationX: position.x, y: position.y))
                }
            }
        }
        let bounds = path.boundingBoxOfPath
        var transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 8 - bounds.minX, ty: bounds.maxY + 8)
        return path.copy(using: &transform)!
    }

    static func appIcon(_ context: CGContext) {
        let tile = CGPath(roundedRect: CGRect(x: 100, y: 100, width: 824, height: 824),
                          cornerWidth: 184, cornerHeight: 184, transform: nil)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 8), blur: 16,
                          color: NSColor.black.withAlphaComponent(0.14).cgColor)
        fill(context, tile, color: paper)
        context.restoreGState()
        fill(context, OsokoBrand.markPath(in: CGRect(x: 176, y: 176, width: 672, height: 672)), color: ink)
    }

    @MainActor static func main() throws {
        let mark = OsokoBrand.markPath(in: CGRect(x: 0, y: 0, width: 64, height: 64))
        try writeSVG(mark, size: CGSize(width: 64, height: 64), name: "logo", color: "#1a1c1a")
        try writeSVG(mark, size: CGSize(width: 64, height: 64), name: "logo-light", color: "#f5f2eb")
        try png(size: CGSize(width: 64, height: 64), scale: 8, file: "assets/logo.png") { fill($0, mark, color: ink) }
        let word = wordmark()
        let wordSize = CGSize(width: ceil(word.boundingBoxOfPath.maxX + 8), height: ceil(word.boundingBoxOfPath.maxY + 8))
        try writeSVG(word, size: wordSize, name: "wordmark", color: "#1a1c1a")
        try writeSVG(word, size: wordSize, name: "wordmark-light", color: "#f5f2eb")
        try png(size: wordSize, scale: 3, file: "assets/wordmark.png") { fill($0, word, color: ink) }
        try png(size: CGSize(width: 1024, height: 1024), file: "assets/app-icon.png", draw: appIcon)

        // Render each icon size directly from the vector geometry.
        let iconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Osoko-\(UUID().uuidString).iconset")
        try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: iconset) }
        for size in [16, 32, 128, 256, 512] {
            for scale in [1, 2] {
                let suffix = scale == 2 ? "@2x" : ""
                try png(size: CGSize(width: 1024, height: 1024), scale: CGFloat(size * scale) / 1024,
                    file: iconset.appendingPathComponent("icon_\(size)x\(size)\(suffix).png").path, draw: appIcon)
            }
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        process.arguments = ["-c", "icns", iconset.path, "-o", "packaging/AppIcon.icns"]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw CocoaError(.fileWriteUnknown) }
        print("Generated logo, outlined wordmarks, app icon, and AppIcon.icns.")
    }
}
