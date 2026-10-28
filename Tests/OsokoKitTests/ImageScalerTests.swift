import XCTest
import AppKit
import CoreGraphics
@testable import OsokoKit

final class ImageScalerTests: XCTestCase {
    private func makeTestPNG(width: Int, height: Int) throws -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            | CGBitmapInfo.byteOrder32Big.rawValue

        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ))

        context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        let image = try XCTUnwrap(context.makeImage())
        let representation = NSBitmapImageRep(cgImage: image)
        return try XCTUnwrap(representation.representation(using: .png, properties: [:]))
    }

    private func writeTemporaryPNG(width: Int, height: Int) throws -> URL {
        let data = try makeTestPNG(width: width, height: height)
        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("ImageScalerTests-\(UUID().uuidString).png")
        try data.write(to: url)
        return url
    }

    func testDownscaleTo1xHalvesPixelDimensions() throws {
        let url = try writeTemporaryPNG(width: 200, height: 120)
        defer { try? FileManager.default.removeItem(at: url) }

        let data = try XCTUnwrap(ImageScaler.downscaleTo1x(imageAt: url))
        let representation = try XCTUnwrap(NSBitmapImageRep(data: data))

        XCTAssertEqual(representation.pixelsWide, 100)
        XCTAssertEqual(representation.pixelsHigh, 60)
    }

    func testDownscaleTo1xRoundsOddDimensionsDown() throws {
        let url = try writeTemporaryPNG(width: 101, height: 61)
        defer { try? FileManager.default.removeItem(at: url) }

        let data = try XCTUnwrap(ImageScaler.downscaleTo1x(imageAt: url))
        let representation = try XCTUnwrap(NSBitmapImageRep(data: data))

        XCTAssertEqual(representation.pixelsWide, 50)
        XCTAssertEqual(representation.pixelsHigh, 30)
    }

    func testDownscaleTo1xClampsTinyImagesToAtLeastOnePixel() throws {
        let url = try writeTemporaryPNG(width: 1, height: 1)
        defer { try? FileManager.default.removeItem(at: url) }

        let data = try XCTUnwrap(ImageScaler.downscaleTo1x(imageAt: url))
        let representation = try XCTUnwrap(NSBitmapImageRep(data: data))

        XCTAssertEqual(representation.pixelsWide, 1)
        XCTAssertEqual(representation.pixelsHigh, 1)
    }

    func testDownscaleTo1xReturnsNilForMissingFile() {
        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("missing-\(UUID().uuidString).png")

        XCTAssertNil(ImageScaler.downscaleTo1x(imageAt: url))
    }

    func testCopyDownscaledToPasteboardWritesPNG() throws {
        let url = try writeTemporaryPNG(width: 80, height: 40)
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertTrue(ImageScaler.copyDownscaledToPasteboard(imageAt: url))

        let pngData = try XCTUnwrap(NSPasteboard.general.data(forType: .png))
        let representation = try XCTUnwrap(NSBitmapImageRep(data: pngData))
        XCTAssertEqual(representation.pixelsWide, 40)
        XCTAssertEqual(representation.pixelsHigh, 20)

        let images = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)
        XCTAssertEqual(images?.count, 1)
    }
}
