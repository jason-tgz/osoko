import AppKit
import Foundation

public struct ScreenshotItem: Identifiable, Sendable {
    public let id: UUID
    public let url: URL
    public let thumbnail: NSImage
    public let pixelWidth: Int
    public let pixelHeight: Int
    public var isPinned: Bool
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        url: URL,
        thumbnail: NSImage,
        pixelWidth: Int,
        pixelHeight: Int,
        isPinned: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.url = url
        self.thumbnail = thumbnail
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.isPinned = isPinned
        self.createdAt = createdAt
    }

    public var aspectRatio: CGFloat {
        guard pixelHeight > 0 else { return 1.0 }
        return CGFloat(pixelWidth) / CGFloat(pixelHeight)
    }

    public var formattedDimensions: String {
        "\(pixelWidth) × \(pixelHeight)"
    }
}
