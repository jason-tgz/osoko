import Foundation
import Vision

public actor TextRecognitionService {
    public static let shared = TextRecognitionService()

    private var cache: [URL: String] = [:]
    private var inFlight: [URL: Task<String, Error>] = [:]

    /// Extracts text from the image at the specified file URL using Apple's Vision framework.
    public func recognizeText(from imageURL: URL) async throws -> String {
        let canonicalURL = imageURL.standardizedFileURL.resolvingSymlinksInPath()

        if let cached = cache[canonicalURL] {
            return cached
        }

        if let runningTask = inFlight[canonicalURL] {
            return try await runningTask.value
        }

        let task = Task.detached(priority: .userInitiated) { () -> String in
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            // Disabling language correction gives a ~150x speedup and prevents
            // code, URLs, and technical strings from being corrupted by spellcheck.
            request.usesLanguageCorrection = false
            request.automaticallyDetectsLanguage = true

            let handler = VNImageRequestHandler(url: canonicalURL, options: [:])
            try handler.perform([request])

            guard let observations = request.results else {
                return ""
            }

            // Sort observations top-to-bottom, then left-to-right
            // Note: In Vision coordinates, y=0 is bottom and y=1 is top
            let sortedObservations = observations.sorted { a, b in
                let yA = a.boundingBox.midY
                let yB = b.boundingBox.midY
                if abs(yA - yB) > 0.025 {
                    return yA > yB // Higher Y in Vision is higher on the screen
                }
                return a.boundingBox.minX < b.boundingBox.minX
            }

            let recognizedStrings = sortedObservations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            return recognizedStrings.joined(separator: "\n")
        }

        inFlight[canonicalURL] = task

        do {
            let result = try await task.value
            cache[canonicalURL] = result
            inFlight.removeValue(forKey: canonicalURL)
            return result
        } catch {
            inFlight.removeValue(forKey: canonicalURL)
            throw error
        }
    }

    /// Pre-warms recognition in the background as soon as a screenshot is captured.
    public func prewarm(imageURL: URL) {
        let canonicalURL = imageURL.standardizedFileURL.resolvingSymlinksInPath()
        guard cache[canonicalURL] == nil, inFlight[canonicalURL] == nil else { return }

        let task = Task.detached(priority: .utility) { [weak self] () -> String in
            guard let self else { return "" }
            return try await self.recognizeText(from: canonicalURL)
        }
        _ = task
    }

    /// Clears cached results when a screenshot is removed.
    public func clearCache(for imageURL: URL) {
        let canonicalURL = imageURL.standardizedFileURL.resolvingSymlinksInPath()
        cache.removeValue(forKey: canonicalURL)
        inFlight.removeValue(forKey: canonicalURL)
    }

    // MARK: - Static Convenience API

    public static func recognizeText(from imageURL: URL) async throws -> String {
        try await shared.recognizeText(from: imageURL)
    }

    public static func prewarm(imageURL: URL) {
        Task {
            await shared.prewarm(imageURL: imageURL)
        }
    }

    public static func clearCache(for imageURL: URL) {
        Task {
            await shared.clearCache(for: imageURL)
        }
    }
}
