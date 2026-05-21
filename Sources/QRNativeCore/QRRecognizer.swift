import AppKit
import CoreGraphics
import Foundation
import Vision

public enum QRRecognizerError: LocalizedError, Equatable {
    case missingImageData
    case recognitionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingImageData:
            return "Unable to read image data."
        case .recognitionFailed(let message):
            return message
        }
    }
}

public struct QRRecognizer: Sendable {
    public init() {}

    public func recognize(in image: NSImage) throws -> [RecognizedQRCode] {
        guard let cgImage = image.qrnativeCGImage else {
            throw QRRecognizerError.missingImageData
        }

        return try recognize(in: cgImage)
    }

    public func recognize(in cgImage: CGImage) throws -> [RecognizedQRCode] {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            throw QRRecognizerError.recognitionFailed(error.localizedDescription)
        }

        return (request.results ?? [])
            .compactMap { observation -> RecognizedQRCode? in
                guard let payload = observation.payloadStringValue, !payload.isEmpty else {
                    return nil
                }

                return RecognizedQRCode(payload: payload, confidence: observation.confidence)
            }
    }
}

extension NSImage {
    public var qrnativeCGImage: CGImage? {
        var rect = NSRect(origin: .zero, size: size)
        if let cgImage = cgImage(forProposedRect: &rect, context: nil, hints: nil) {
            return cgImage
        }

        guard
            let tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffRepresentation)
        else {
            return nil
        }

        return bitmap.cgImage
    }
}

