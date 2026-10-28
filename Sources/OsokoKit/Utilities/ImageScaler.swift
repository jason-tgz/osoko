import AppKit
import CoreGraphics
import ImageIO

/// Image scaling helpers used by the screenshot action slots.
public enum ImageScaler: Sendable {
    /// Downsamples the image at `url` to half of its pixel dimensions and returns PNG data.
    ///
    /// Retina screenshots are captured at 2x, so halving the pixel dimensions produces
    /// an image whose pixels map 1:1 to logical points.
    public static func downscaleTo1x(imageAt url: URL) -> Data? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(
                  source,
                  0,
                  [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
              ) else {
            return nil
        }

        let originalWidth = image.width
        let originalHeight = image.height
        guard originalWidth > 0, originalHeight > 0 else { return nil }

        let targetWidth = max(1, originalWidth / 2)
        let targetHeight = max(1, originalHeight / 2)

        // Preserve a wide-gamut RGB source (e.g. Display P3) when possible so the
        // downscaled copy stays color-accurate.
        let colorSpace = image.colorSpace.flatMap { space -> CGColorSpace? in
            space.model == .rgb ? space : nil
        } ?? CGColorSpace(name: CGColorSpace.sRGB)
            ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            | CGBitmapInfo.byteOrder32Big.rawValue

        guard let context = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))

        guard let scaledImage = context.makeImage() else { return nil }

        let representation = NSBitmapImageRep(cgImage: scaledImage)
        representation.size = NSSize(width: targetWidth, height: targetHeight)
        return representation.representation(using: .png, properties: [:])
    }

    /// Copies a 1x downscaled PNG representation of the image at `url` to the general pasteboard.
    @discardableResult
    public static func copyDownscaledToPasteboard(imageAt url: URL) -> Bool {
        guard let pngData = downscaleTo1x(imageAt: url) else { return false }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        guard let image = NSImage(data: pngData) else {
            return pasteboard.setData(pngData, forType: .png)
        }

        // Publish both the exact PNG bytes and the NSImage's TIFF representation so
        // receiving apps can choose the format they understand best.
        let item = NSPasteboardItem()
        item.setData(pngData, forType: .png)
        if let tiffData = image.tiffRepresentation {
            item.setData(tiffData, forType: .tiff)
        }
        return pasteboard.writeObjects([item])
    }
}
