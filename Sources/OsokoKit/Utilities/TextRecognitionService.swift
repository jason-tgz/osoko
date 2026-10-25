import Foundation
import Vision
import CoreImage

public enum TextRecognitionService {
    /// Extracts text from the image at the specified file URL using Apple's Vision framework.
    public static func recognizeText(from imageURL: URL) async throws -> String {
        guard let ciImage = CIImage(contentsOf: imageURL) else {
            throw NSError(domain: "com.osoko.ocr", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image for OCR."])
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
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

                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
