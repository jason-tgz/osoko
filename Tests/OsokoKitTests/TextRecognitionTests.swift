import XCTest
import AppKit
@testable import OsokoKit

final class TextRecognitionTests: XCTestCase {
    func testTextRecognitionServiceExtractsText() async throws {
        // Create an image with rendered text
        let size = CGSize(width: 300, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()

        let string = "OSOKO OCR TEST" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 24),
            .foregroundColor: NSColor.black
        ]
        string.draw(at: CGPoint(x: 20, y: 35), withAttributes: attributes)
        image.unlockFocus()

        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            XCTFail("Failed to create test PNG image")
            return
        }

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ocr_test_\(UUID().uuidString).png")
        try png.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let extractedText = try await TextRecognitionService.recognizeText(from: tempURL)
        XCTAssertTrue(extractedText.localizedCaseInsensitiveContains("OSOKO") || extractedText.localizedCaseInsensitiveContains("OCR"), "Extracted text was: \(extractedText)")
    }
}
