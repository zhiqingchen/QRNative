import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import UniformTypeIdentifiers

public enum QRCodeGeneratorError: LocalizedError, Equatable {
    case emptyContent
    case filterFailed
    case renderFailed
    case pngEncodingFailed

    public var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "Content is empty."
        case .filterFailed:
            return "Unable to create a QR code from the provided content."
        case .renderFailed:
            return "Unable to render the QR code image."
        case .pngEncodingFailed:
            return "Unable to encode the QR code as PNG."
        }
    }
}

public struct QRCodeGenerator: Sendable {
    public init() {}

    public func ciImage(
        for content: String,
        correctionLevel: QRCorrectionLevel = .medium
    ) throws -> CIImage {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw QRCodeGeneratorError.emptyContent
        }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(content.utf8)
        filter.correctionLevel = correctionLevel.rawValue

        guard let image = filter.outputImage else {
            throw QRCodeGeneratorError.filterFailed
        }

        return image
    }

    public func cgImage(
        for content: String,
        correctionLevel: QRCorrectionLevel = .medium,
        sideLength: CGFloat = 768
    ) throws -> CGImage {
        let sourceImage = try ciImage(for: content, correctionLevel: correctionLevel)
        let extent = sourceImage.extent.integral
        let scale = max(1, floor(sideLength / max(extent.width, extent.height)))
        let scaledImage = sourceImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext(options: [.useSoftwareRenderer: false])

        guard let rendered = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            throw QRCodeGeneratorError.renderFailed
        }

        return rendered
    }

    public func nsImage(
        for content: String,
        correctionLevel: QRCorrectionLevel = .medium,
        sideLength: CGFloat = 768
    ) throws -> NSImage {
        let cgImage = try cgImage(for: content, correctionLevel: correctionLevel, sideLength: sideLength)
        let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        image.isTemplate = false
        return image
    }

    public func pngData(
        for content: String,
        correctionLevel: QRCorrectionLevel = .medium,
        sideLength: CGFloat = 1024
    ) throws -> Data {
        let cgImage = try cgImage(for: content, correctionLevel: correctionLevel, sideLength: sideLength)
        let representation = NSBitmapImageRep(cgImage: cgImage)

        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw QRCodeGeneratorError.pngEncodingFailed
        }

        return data
    }
}

