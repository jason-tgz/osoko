import XCTest
import AppKit
import Foundation
@testable import OsokoKit

final class CardActionTests: XCTestCase {
    func testCardActionKindMetadata() {
        XCTAssertEqual(CardActionKind.allCases.count, 11)

        XCTAssertEqual(CardActionKind.copyDownscaled.rawValue, "copy_downscaled")
        XCTAssertEqual(CardActionKind.copyOriginal.rawValue, "copy_original")
        XCTAssertEqual(CardActionKind.copyOCR.rawValue, "copy_ocr")
        XCTAssertEqual(CardActionKind.copyQRLink.rawValue, "copy_qr_link")
        XCTAssertEqual(CardActionKind.openQRLink.rawValue, "open_qr_link")
        XCTAssertEqual(CardActionKind.saveToFolder.rawValue, "save_to_folder")
        XCTAssertEqual(CardActionKind.saveAs.rawValue, "save_as")
        XCTAssertEqual(CardActionKind.pin.rawValue, "pin")
        XCTAssertEqual(CardActionKind.share.rawValue, "share")
        XCTAssertEqual(CardActionKind.openInPreview.rawValue, "open_preview")
        XCTAssertEqual(CardActionKind.none.rawValue, "none")

        XCTAssertEqual(CardActionKind.copyDownscaled.displayName, "Copy 1x Downscaled")
        XCTAssertEqual(CardActionKind.copyOriginal.displayName, "Copy 2x Original")
        XCTAssertEqual(CardActionKind.copyOCR.displayName, "Copy Text (OCR)")
        XCTAssertEqual(CardActionKind.copyQRLink.displayName, "Copy QR Code Link")
        XCTAssertEqual(CardActionKind.openQRLink.displayName, "Open QR Link")
        XCTAssertEqual(CardActionKind.saveToFolder.displayName, "Save to Location")
        XCTAssertEqual(CardActionKind.saveAs.displayName, "Save As...")
        XCTAssertEqual(CardActionKind.pin.displayName, "Pin to Stack")
        XCTAssertEqual(CardActionKind.share.displayName, "Share...")
        XCTAssertEqual(CardActionKind.openInPreview.displayName, "Open in Preview")
        XCTAssertEqual(CardActionKind.none.displayName, "None (Hidden)")

        XCTAssertEqual(CardActionKind.copyDownscaled.iconName, "1.circle")
        XCTAssertEqual(CardActionKind.copyOriginal.iconName, "doc.on.doc")
        XCTAssertEqual(CardActionKind.copyOCR.iconName, "text.viewfinder")
        XCTAssertEqual(CardActionKind.copyQRLink.iconName, "qrcode")
        XCTAssertEqual(CardActionKind.openQRLink.iconName, "arrow.up.right.square")
        XCTAssertEqual(CardActionKind.saveToFolder.iconName, "arrow.down.to.line")
        XCTAssertEqual(CardActionKind.saveAs.iconName, "square.and.pencil")
        XCTAssertEqual(CardActionKind.pin.iconName, "pin")
        XCTAssertEqual(CardActionKind.share.iconName, "square.and.arrow.up")
        XCTAssertEqual(CardActionKind.openInPreview.iconName, "eye")
        XCTAssertEqual(CardActionKind.none.iconName, "minus.circle")

        for action in CardActionKind.allCases {
            XCTAssertEqual(action.id, action.rawValue)
            XCTAssertFalse(action.displayName.isEmpty)
            XCTAssertFalse(action.iconName.isEmpty)
            XCTAssertFalse(action.tooltip.isEmpty)
        }
    }

    func testCardActionKindCodableRoundTrip() throws {
        for action in CardActionKind.allCases {
            let data = try JSONEncoder().encode(action)
            let decoded = try JSONDecoder().decode(CardActionKind.self, from: data)
            XCTAssertEqual(decoded, action)
        }
    }

    @MainActor
    func testSettingsDefaultsAndPersistence() throws {
        let defaults = UserDefaults.standard
        let keys = [
            "osoko.topActionSlot1",
            "osoko.topActionSlot2",
            "osoko.bottomActionSlot1",
            "osoko.bottomActionSlot2",
            "osoko.primaryClickAction",
            "osoko.doubleClickAction",
            "osoko.enableHoverShortcuts"
        ]
        let originals = keys.map { defaults.object(forKey: $0) }
        defer {
            for (key, original) in zip(keys, originals) {
                if let original {
                    defaults.set(original, forKey: key)
                } else {
                    defaults.removeObject(forKey: key)
                }
            }
        }

        for key in keys {
            defaults.removeObject(forKey: key)
        }

        let fresh = OsokoSettings()
        XCTAssertEqual(fresh.topActionSlot1, .saveToFolder)
        XCTAssertEqual(fresh.topActionSlot2, .pin)
        XCTAssertEqual(fresh.bottomActionSlot1, .copyDownscaled)
        XCTAssertEqual(fresh.bottomActionSlot2, .share)
        XCTAssertEqual(fresh.primaryClickAction, .copyOriginal)
        XCTAssertEqual(fresh.doubleClickAction, .openInPreview)
        XCTAssertTrue(fresh.enableHoverShortcuts)

        fresh.topActionSlot1 = .copyOCR
        fresh.topActionSlot2 = .none
        fresh.bottomActionSlot1 = .saveAs
        fresh.bottomActionSlot2 = .copyOriginal
        fresh.primaryClickAction = .copyDownscaled
        fresh.doubleClickAction = .share
        fresh.enableHoverShortcuts = false

        XCTAssertEqual(defaults.string(forKey: "osoko.topActionSlot1"), "copy_ocr")
        XCTAssertEqual(defaults.string(forKey: "osoko.topActionSlot2"), "none")
        XCTAssertEqual(defaults.string(forKey: "osoko.bottomActionSlot1"), "save_as")
        XCTAssertEqual(defaults.string(forKey: "osoko.bottomActionSlot2"), "copy_original")
        XCTAssertEqual(defaults.string(forKey: "osoko.primaryClickAction"), "copy_downscaled")
        XCTAssertEqual(defaults.string(forKey: "osoko.doubleClickAction"), "share")
        XCTAssertEqual(defaults.object(forKey: "osoko.enableHoverShortcuts") as? Bool, false)

        let reloaded = OsokoSettings()
        XCTAssertEqual(reloaded.topActionSlot1, .copyOCR)
        XCTAssertEqual(reloaded.topActionSlot2, .none)
        XCTAssertEqual(reloaded.bottomActionSlot1, .saveAs)
        XCTAssertEqual(reloaded.bottomActionSlot2, .copyOriginal)
        XCTAssertEqual(reloaded.primaryClickAction, .copyDownscaled)
        XCTAssertEqual(reloaded.doubleClickAction, .share)
        XCTAssertFalse(reloaded.enableHoverShortcuts)
    }

    @MainActor
    func testInvalidPersistedValuesFallBackToDefaults() {
        let defaults = UserDefaults.standard
        let key = "osoko.topActionSlot1"
        let original = defaults.object(forKey: key)
        defer {
            if let original {
                defaults.set(original, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        defaults.set("not-a-real-action", forKey: key)

        let settings = OsokoSettings()
        XCTAssertEqual(settings.topActionSlot1, .saveToFolder)
    }

    @MainActor
    func testActionZonesFollowConfiguredSlots() {
        let view = ScreenshotGrabView(frame: NSRect(x: 0, y: 0, width: 185, height: 140))
        view.topActions = [.saveToFolder, .pin]
        view.bottomActions = [.copyDownscaled, .share]

        XCTAssertEqual(view.actionZone(at: NSPoint(x: 5, y: 5)), .close)
        XCTAssertEqual(view.actionZone(at: NSPoint(x: 135, y: 5)), .action(.saveToFolder))
        XCTAssertEqual(view.actionZone(at: NSPoint(x: 170, y: 5)), .action(.pin))
        XCTAssertEqual(view.actionZone(at: NSPoint(x: 135, y: 130)), .action(.copyDownscaled))
        XCTAssertEqual(view.actionZone(at: NSPoint(x: 170, y: 130)), .action(.share))
        XCTAssertNil(view.actionZone(at: NSPoint(x: 90, y: 70)))
    }

    @MainActor
    func testHiddenSlotsAreNotHitTested() {
        let view = ScreenshotGrabView(frame: NSRect(x: 0, y: 0, width: 185, height: 140))
        view.topActions = [.none, .pin]
        view.bottomActions = [.none, .none]

        XCTAssertEqual(view.actionZone(at: NSPoint(x: 170, y: 5)), .action(.pin))
        XCTAssertNil(view.actionZone(at: NSPoint(x: 135, y: 5)))
        XCTAssertNil(view.actionZone(at: NSPoint(x: 170, y: 130)))
    }
}
