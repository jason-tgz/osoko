import Foundation
import Vision

/// Detects QR codes and barcodes in screenshots using Apple's Vision framework.
public actor BarcodeDetectionService {
    public static let shared = BarcodeDetectionService()

    private var cache: [URL: String] = [:]
    private var inFlight: [URL: Task<String?, Error>] = [:]

    /// Detects the first non-empty barcode payload in the image at `imageURL`.
    public func detectBarcode(
        from imageURL: URL,
        symbologies: [VNBarcodeSymbology] = [.qr, .aztec, .dataMatrix, .ean13, .code128]
    ) async throws -> String? {
        let canonicalURL = imageURL.standardizedFileURL.resolvingSymlinksInPath()

        if let cached = cache[canonicalURL] {
            return cached
        }

        if let runningTask = inFlight[canonicalURL] {
            return try await runningTask.value
        }

        // Vision symbologies are not guaranteed to be Sendable, so pass their raw
        // values into the detached task and rebuild them there.
        let requestedRawValues = (symbologies.isEmpty ? [.qr] : symbologies).map(\.rawValue)

        let task = Task.detached(priority: .userInitiated) { () -> String? in
            let request = VNDetectBarcodesRequest()
            request.symbologies = requestedRawValues.map { VNBarcodeSymbology(rawValue: $0) }

            let handler = VNImageRequestHandler(url: canonicalURL, options: [:])
            try handler.perform([request])

            guard let observations = request.results else { return nil }

            for observation in observations {
                guard let rawValue = observation.payloadStringValue else { continue }
                let payload = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if !payload.isEmpty {
                    return payload
                }
            }

            return nil
        }

        inFlight[canonicalURL] = task

        do {
            let result = try await task.value
            inFlight.removeValue(forKey: canonicalURL)
            if let result, !result.isEmpty {
                cache[canonicalURL] = result
            }
            return result
        } catch {
            inFlight.removeValue(forKey: canonicalURL)
            throw error
        }
    }

    /// Removes a cached barcode result so the image will be scanned again next time.
    public func clearCache(for imageURL: URL) {
        let canonicalURL = imageURL.standardizedFileURL.resolvingSymlinksInPath()
        cache.removeValue(forKey: canonicalURL)
        inFlight.removeValue(forKey: canonicalURL)
    }

    // MARK: - Static Convenience API

    public static func detectBarcode(from url: URL) async throws -> String? {
        try await shared.detectBarcode(from: url)
    }

    public static func prewarm(imageURL: URL) {
        Task.detached(priority: .utility) {
            _ = try? await shared.detectBarcode(from: imageURL)
        }
    }

    public static func clearCache(for url: URL) {
        let canonicalURL = url.standardizedFileURL.resolvingSymlinksInPath()
        Task.detached(priority: .userInitiated) {
            await shared.clearCache(for: canonicalURL)
        }
    }
}
