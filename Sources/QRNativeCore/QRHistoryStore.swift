import Combine
import Foundation

public enum QRHistoryStoreError: LocalizedError, Equatable {
    case applicationSupportUnavailable

    public var errorDescription: String? {
        switch self {
        case .applicationSupportUnavailable:
            return "Unable to locate the Application Support directory."
        }
    }
}

@MainActor
public final class QRHistoryStore: ObservableObject {
    @Published public private(set) var records: [QRCodeRecord] = []

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL? = nil) throws {
        self.fileURL = try fileURL ?? Self.defaultFileURL()
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        try load()
    }

    public static func defaultFileURL() throws -> URL {
        guard let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw QRHistoryStoreError.applicationSupportUnavailable
        }

        return supportURL
            .appendingPathComponent("QRNative", isDirectory: true)
            .appendingPathComponent("history.json", isDirectory: false)
    }

    public func load() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            records = []
            return
        }

        let data = try Data(contentsOf: fileURL)
        records = try decoder.decode([QRCodeRecord].self, from: data)
            .sorted { $0.createdAt > $1.createdAt }
    }

    @discardableResult
    public func add(
        content: String,
        source: QRRecordSource,
        title: String? = nil,
        correctionLevel: QRCorrectionLevel = .medium
    ) throws -> QRCodeRecord {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw QRCodeGeneratorError.emptyContent
        }

        if let existingIndex = records.firstIndex(where: { $0.content.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed }) {
            var existing = records.remove(at: existingIndex)
            existing.content = trimmed
            existing.createdAt = Date()
            existing.source = source
            existing.title = title ?? existing.title
            existing.correctionLevel = correctionLevel
            records.insert(existing, at: 0)
            try save()
            return existing
        }

        let record = QRCodeRecord(
            content: trimmed,
            source: source,
            title: title,
            correctionLevel: correctionLevel
        )
        records.insert(record, at: 0)
        try save()
        return record
    }

    public func delete(_ record: QRCodeRecord) throws {
        records.removeAll { $0.id == record.id }
        try save()
    }

    public func deleteAll() throws {
        records.removeAll()
        try save()
    }

    public func search(_ query: String) -> [QRCodeRecord] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return records
        }

        return records.filter { record in
            record.content.localizedCaseInsensitiveContains(trimmed)
                || record.displayTitle.localizedCaseInsensitiveContains(trimmed)
                || record.source.label.localizedCaseInsensitiveContains(trimmed)
        }
    }

    public func save() throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(records)
        try data.write(to: fileURL, options: [.atomic])
    }
}
