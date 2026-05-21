import Foundation

public enum QRCorrectionLevel: String, CaseIterable, Codable, Identifiable, Sendable {
    case low = "L"
    case medium = "M"
    case quartile = "Q"
    case high = "H"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .low:
            return "L"
        case .medium:
            return "M"
        case .quartile:
            return "Q"
        case .high:
            return "H"
        }
    }

    public var detail: String {
        switch self {
        case .low:
            return "7%"
        case .medium:
            return "15%"
        case .quartile:
            return "25%"
        case .high:
            return "30%"
        }
    }
}

public enum QRRecordSource: String, Codable, CaseIterable, Identifiable, Sendable {
    case typed
    case clipboard
    case service
    case recognized
    case imported

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .typed:
            return "Typed"
        case .clipboard:
            return "Clipboard"
        case .service:
            return "Service"
        case .recognized:
            return "Recognized"
        case .imported:
            return "Imported"
        }
    }
}

public struct QRCodeRecord: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var content: String
    public var createdAt: Date
    public var source: QRRecordSource
    public var title: String?
    public var correctionLevel: QRCorrectionLevel

    public init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = Date(),
        source: QRRecordSource,
        title: String? = nil,
        correctionLevel: QRCorrectionLevel = .medium
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.source = source
        self.title = title
        self.correctionLevel = correctionLevel
    }

    public var displayTitle: String {
        if let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return title
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Untitled QR Code"
        }

        return String(trimmed.prefix(64))
    }
}

public struct RecognizedQRCode: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var payload: String
    public var confidence: Float

    public init(id: UUID = UUID(), payload: String, confidence: Float) {
        self.id = id
        self.payload = payload
        self.confidence = confidence
    }
}
