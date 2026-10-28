import Foundation

/// The actions that can be bound to a screenshot card's action slots and click gestures.
public enum CardActionKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case copyDownscaled = "copy_downscaled"
    case copyOriginal = "copy_original"
    case copyOCR = "copy_ocr"
    case redactSensitive = "redact_sensitive"
    case copyQRLink = "copy_qr_link"
    case openQRLink = "open_qr_link"
    case saveToFolder = "save_to_folder"
    case saveAs = "save_as"
    case pin = "pin"
    case share = "share"
    case openInPreview = "open_preview"
    case none = "none"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .copyDownscaled: return "Copy 1x Downscaled"
        case .copyOriginal: return "Copy 2x Original"
        case .copyOCR: return "Copy Text (OCR)"
        case .redactSensitive: return "Redact Sensitive Data"
        case .copyQRLink: return "Copy QR Code Link"
        case .openQRLink: return "Open QR Link"
        case .saveToFolder: return "Save to Location"
        case .saveAs: return "Save As..."
        case .pin: return "Pin to Stack"
        case .share: return "Share..."
        case .openInPreview: return "Open in Preview"
        case .none: return "None (Hidden)"
        }
    }

    public var iconName: String {
        switch self {
        case .copyDownscaled: return "1.circle"
        case .copyOriginal: return "doc.on.doc"
        case .copyOCR: return "text.viewfinder"
        case .redactSensitive: return "shield.lefthalf.filled"
        case .copyQRLink: return "qrcode"
        case .openQRLink: return "arrow.up.right.square"
        case .saveToFolder: return "arrow.down.to.line"
        case .saveAs: return "square.and.pencil"
        case .pin: return "pin"
        case .share: return "square.and.arrow.up"
        case .openInPreview: return "eye"
        case .none: return "minus.circle"
        }
    }

    public var tooltip: String {
        switch self {
        case .copyDownscaled: return "Copy 1x logical resolution to clipboard"
        case .copyOriginal: return "Copy original 2x capture to clipboard"
        case .copyOCR: return "Extract and copy text"
        case .redactSensitive: return "Redact API keys, tokens, and emails with solid black bars"
        case .copyQRLink: return "Copy URL or text from detected QR code"
        case .openQRLink: return "Open QR link in default browser"
        case .saveToFolder: return "Save directly to configured folder"
        case .saveAs: return "Prompt to rename and save"
        case .pin: return "Keep card in stack"
        case .share: return "Open native macOS Share menu"
        case .openInPreview: return "Open in Preview app"
        case .none: return "Hide this action slot"
        }
    }
}
