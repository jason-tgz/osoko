import XCTest
import AppKit
import CoreImage
import Foundation
@testable import OsokoKit

final class BarcodeDetectionTests: XCTestCase {
    private let testPayload = "https://osoko.app/test"

    private func makeQRCodePNG(payload: String) throws -> URL {
        let filter = try XCTUnwrap(CIFilter(name: "CIQRCodeGenerator"))
        filter.setValue(payload.data(using: .utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        let ciImage = try XCTUnwrap(filter.outputImage)
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)

        let tiff = try XCTUnwrap(nsImage.tiffRepresentation)
        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: tiff))
        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))

        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("BarcodeDetectionTests-\(UUID().uuidString).png")
        try png.write(to: url)
        return url
    }

    private func makeBlankPNG() throws -> URL {
        let image = NSImage(size: NSSize(width: 80, height: 80))
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: 80, height: 80).fill()
        image.unlockFocus()

        let tiff = try XCTUnwrap(image.tiffRepresentation)
        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: tiff))
        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))

        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("BarcodeDetectionTests-\(UUID().uuidString).png")
        try png.write(to: url)
        return url
    }

    func testDetectsQRCodePayload() async throws {
        let url = try makeQRCodePNG(payload: testPayload)
        defer { try? FileManager.default.removeItem(at: url) }

        let detected = try await BarcodeDetectionService.detectBarcode(from: url)
        XCTAssertEqual(detected, testPayload)
        await BarcodeDetectionService.shared.clearCache(for: url)
    }

    func testCacheHitAndClearing() async throws {
        let url = try makeQRCodePNG(payload: testPayload)
        defer { try? FileManager.default.removeItem(at: url) }

        let first = try await BarcodeDetectionService.detectBarcode(from: url)
        XCTAssertEqual(first, testPayload)

        // The cached result should be returned even after the source disappears.
        try FileManager.default.removeItem(at: url)
        let cached = try await BarcodeDetectionService.detectBarcode(from: url)
        XCTAssertEqual(cached, testPayload)

        // Static clearing is asynchronous; poll briefly until the entry is evicted.
        BarcodeDetectionService.clearCache(for: url)
        var cleared = false
        for _ in 0..<50 {
            if (try? await BarcodeDetectionService.detectBarcode(from: url)) == nil {
                cleared = true
                break
            }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertTrue(cleared, "Barcode cache was not cleared")
    }

    func testImageWithoutBarcodeReturnsNil() async throws {
        let url = try makeBlankPNG()
        defer { try? FileManager.default.removeItem(at: url) }

        let detected = try await BarcodeDetectionService.detectBarcode(from: url)
        XCTAssertNil(detected)
        await BarcodeDetectionService.shared.clearCache(for: url)
    }
}
