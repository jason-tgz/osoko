import XCTest
import Foundation
@testable import OsokoKit

final class ExportTrackerTests: XCTestCase {
    func testExportTrackerRegistersAndIdentifiesFiles() throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .resolvingSymlinksInPath()
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = tempDir.appendingPathComponent("Screenshot 2026-10-24 at 10.00.00 AM.png")
        try Data("dummy-image-bytes".utf8).write(to: testFile)

        XCTAssertFalse(ExportTracker.shared.isExported(url: testFile))

        ExportTracker.shared.register(url: testFile)

        XCTAssertTrue(ExportTracker.shared.isExported(url: testFile))
        // Should not be treated as a new incoming screenshot capture
        XCTAssertFalse(ScreenshotCaptureService.isScreenshot(testFile))
    }

    func testExportExtendedAttributeHandling() throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .resolvingSymlinksInPath()
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = tempDir.appendingPathComponent("Screenshot_Saved_File.png")
        try Data("dummy-image-bytes".utf8).write(to: testFile)

        testFile.withUnsafeFileSystemRepresentation { p in
            guard let p else { return }
            let val = "1"
            setxattr(p, "com.osoko.saved", val, val.utf8.count, 0, 0)
        }

        XCTAssertTrue(ExportTracker.shared.isExported(url: testFile))
        XCTAssertFalse(ScreenshotCaptureService.isScreenshot(testFile))
    }
}
