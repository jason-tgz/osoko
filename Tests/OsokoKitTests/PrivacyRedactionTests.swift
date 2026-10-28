import XCTest
import AppKit
import Foundation
@testable import OsokoKit

final class PrivacyRedactionTests: XCTestCase {
    private let apiKey = "sk-proj-test12345678901234567890"
    private let email = "alice@example.com"

    private func makeImage(lines: [String]) throws -> URL {
        let size = NSSize(width: 1200, height: 360)
        let image = NSImage(size: size)

        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 40),
            .foregroundColor: NSColor.black,
        ]

        var y: CGFloat = 210
        for line in lines {
            (line as NSString).draw(at: CGPoint(x: 40, y: y), withAttributes: attributes)
            y -= 100
        }
        image.unlockFocus()

        let tiff = try XCTUnwrap(image.tiffRepresentation)
        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: tiff))
        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))

        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("PrivacyRedactionTests-\(UUID().uuidString).png")
        try png.write(to: url)
        return url
    }

    func testRedactsAPIKeyAndEmail() async throws {
        let url = try makeImage(lines: [apiKey, email])
        defer { try? FileManager.default.removeItem(at: url) }

        let redaction = try await PrivacyRedactionService.redactSensitiveData(imageAt: url)
        let result = try XCTUnwrap(redaction)

        XCTAssertGreaterThanOrEqual(result.matchCount, 2)
        XCTAssertFalse(result.redactedPNGData.isEmpty)
        let redactedBitmap = try XCTUnwrap(NSBitmapImageRep(data: result.redactedPNGData))
        XCTAssertEqual(Int(result.redactedImage.size.width), redactedBitmap.pixelsWide)
        XCTAssertEqual(Int(result.redactedImage.size.height), redactedBitmap.pixelsHigh)
    }

    func testCleanImageHasNoMatches() async throws {
        let url = try makeImage(lines: ["Hello from Osoko", "Nothing secret here"])
        defer { try? FileManager.default.removeItem(at: url) }

        let redaction = try await PrivacyRedactionService.redactSensitiveData(imageAt: url)
        let result = try XCTUnwrap(redaction)

        XCTAssertEqual(result.matchCount, 0)
        XCTAssertEqual(result.redactedPNGData, try Data(contentsOf: url))
    }

    func testCopyRedactedWritesPasteboard() async throws {
        let url = try makeImage(lines: [apiKey, email])
        defer { try? FileManager.default.removeItem(at: url) }

        NSPasteboard.general.clearContents()
        let count = try await PrivacyRedactionService.copyRedactedToPasteboard(imageAt: url)

        XCTAssertGreaterThanOrEqual(count, 2)

        let pngData = try XCTUnwrap(NSPasteboard.general.data(forType: .png))
        XCTAssertFalse(pngData.isEmpty)

        let images = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)
        XCTAssertFalse((images ?? []).isEmpty)
    }
}
