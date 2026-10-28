import AppKit
import CoreGraphics
import Foundation
import Vision

/// The output of a privacy-redaction pass over a screenshot.
public struct RedactionResult: Sendable {
    public let redactedPNGData: Data
    public let redactedImage: NSImage
    public let matchCount: Int

    public init(redactedPNGData: Data, redactedImage: NSImage, matchCount: Int) {
        self.redactedPNGData = redactedPNGData
        self.redactedImage = redactedImage
        self.matchCount = matchCount
    }
}

/// Detects and redacts sensitive text (API keys, tokens, emails, cards, and
/// password-bearing URLs) from screenshots using Vision OCR.
public enum PrivacyRedactionService: Sendable {
    private static let patternStrings: [String] = [
        #"\b(?:sk|pk)_(?:live|test)_[a-zA-Z0-9]{20,}\b"#,
        #"\bsk-[a-zA-Z0-9_\-]{20,}\b"#,
        #"\b(?:ghp|gho|ghu|ghs|ghr)_[a-zA-Z0-9]{36,}\b"#,
        #"\bAKIA[0-9A-Z]{16}\b"#,
        #"\beyJ[a-zA-Z0-9_\-]{10,}\.eyJ[a-zA-Z0-9_\-]{10,}\.[a-zA-Z0-9_\-]{10,}\b"#,
        #"(?i)\b(?:bearer\s+)([a-zA-Z0-9_\-\.]{24,})\b"#,
        #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"#,
        #"\b(?:\d{4}[ -]?){3}\d{4}\b"#,
        #"https?://[^:\s]+:[^@\s]+@[^\s]+"#,
    ]

    private enum RedactionError: Error {
        case invalidImage
        case encodingFailed
    }

    /// Returns a redacted copy of the image, or the original image when no
    /// sensitive text is detected.
    public static func redactSensitiveData(imageAt url: URL) async throws -> RedactionResult? {
        try await Task.detached(priority: .userInitiated) {
            try performRedaction(imageAt: url)
        }.value
    }

    /// Copies the redacted image to the pasteboard and returns the number of
    /// redacted matches. The pasteboard is untouched when nothing matched.
    public static func copyRedactedToPasteboard(imageAt url: URL) async throws -> Int {
        guard let result = try await redactSensitiveData(imageAt: url),
              result.matchCount > 0 else {
            return 0
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let item = NSPasteboardItem()
        item.setData(result.redactedPNGData, forType: .png)
        if let tiffData = result.redactedImage.tiffRepresentation {
            item.setData(tiffData, forType: .tiff)
        }
        pasteboard.writeObjects([item])
        return result.matchCount
    }

    // MARK: - OCR

    private static func performRedaction(imageAt url: URL) throws -> RedactionResult {
        let boxes = try sensitiveTextBoxes(imageAt: url)

        if boxes.isEmpty {
            let originalData = try Data(contentsOf: url)
            guard let originalImage = NSImage(data: originalData) else {
                throw RedactionError.invalidImage
            }
            return RedactionResult(
                redactedPNGData: originalData,
                redactedImage: originalImage,
                matchCount: 0
            )
        }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let originalCGImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw RedactionError.invalidImage
        }

        let width = originalCGImage.width
        let height = originalCGImage.height
        guard width > 0, height > 0 else { throw RedactionError.invalidImage }

        let colorSpace = originalCGImage.colorSpace.flatMap { space -> CGColorSpace? in
            space.model == .rgb ? space : nil
        } ?? CGColorSpace(name: CGColorSpace.sRGB)
            ?? CGColorSpaceCreateDeviceRGB()

        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            | CGBitmapInfo.byteOrder32Big.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw RedactionError.invalidImage
        }

        let imageBounds = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(originalCGImage, in: imageBounds)

        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1.0))
        for box in boxes {
            let rect = CGRect(
                x: box.origin.x * CGFloat(width) - 2,
                y: box.origin.y * CGFloat(height) - 2,
                width: box.size.width * CGFloat(width) + 4,
                height: box.size.height * CGFloat(height) + 4
            ).intersection(imageBounds)

            guard !rect.isNull, rect.width > 0, rect.height > 0 else { continue }
            context.addPath(CGPath(roundedRect: rect, cornerWidth: 3, cornerHeight: 3, transform: nil))
            context.fillPath()
        }

        guard let redactedCGImage = context.makeImage() else {
            throw RedactionError.encodingFailed
        }

        let representation = NSBitmapImageRep(cgImage: redactedCGImage)
        representation.size = NSSize(width: width, height: height)
        guard let pngData = representation.representation(using: .png, properties: [:]) else {
            throw RedactionError.encodingFailed
        }

        let redactedImage = NSImage(
            cgImage: redactedCGImage,
            size: NSSize(width: width, height: height)
        )

        return RedactionResult(
            redactedPNGData: pngData,
            redactedImage: redactedImage,
            matchCount: boxes.count
        )
    }

    private static func sensitiveTextBoxes(imageAt url: URL) throws -> [CGRect] {
        let observations = try recognizeText(in: url)
        let regexes = patternStrings.compactMap { try? NSRegularExpression(pattern: $0) }
        var boxes: [CGRect] = []

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let text = candidate.string
            let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)

            for regex in regexes {
                regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                    guard let match,
                          let matchRange = Range(match.range, in: text) else { return }

                    let boxObservation = (try? candidate.boundingBox(for: matchRange)) ?? nil
                    boxes.append(boxObservation?.boundingBox ?? observation.boundingBox)
                }
            }
        }

        return boxes
    }

    private static func recognizeText(in url: URL) throws -> [VNRecognizedTextObservation] {
        func makeRequest(useFastRecognition: Bool) -> VNRecognizeTextRequest {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = useFastRecognition ? .fast : .accurate
            request.usesLanguageCorrection = false
            return request
        }

        let handler = VNImageRequestHandler(url: url, options: [:])

        let accurateRequest = makeRequest(useFastRecognition: false)
        do {
            try handler.perform([accurateRequest])
            return accurateRequest.results ?? []
        } catch {
            // The high-accuracy model is unavailable in some environments.
            let fallbackRequest = makeRequest(useFastRecognition: true)
            try handler.perform([fallbackRequest])
            return fallbackRequest.results ?? []
        }
    }
}
