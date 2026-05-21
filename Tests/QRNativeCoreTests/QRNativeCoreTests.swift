import AppKit
import Testing
@testable import QRNativeCore

@Suite("QRNative core")
struct QRNativeCoreTests {
    @Test("QR generator produces PNG data")
    func generatorProducesPNGData() throws {
        let data = try QRCodeGenerator().pngData(for: "https://example.com", correctionLevel: .high)

        #expect(data.starts(with: [0x89, 0x50, 0x4E, 0x47]))
        #expect(data.count > 1_000)
    }

    @Test("Generated QR code can be recognized")
    func generatedQRCodeCanBeRecognized() throws {
        let expected = "QRNative recognition fixture"
        let image = try QRCodeGenerator().nsImage(for: expected, correctionLevel: .medium)
        let recognized = try QRRecognizer().recognize(in: image)

        #expect(recognized.map(\.payload).contains(expected))
    }

    @Test("Generator trims content before encoding")
    func generatorTrimsContentBeforeEncoding() throws {
        let generator = QRCodeGenerator()
        let recognizer = QRRecognizer()

        let padded = try recognizer.recognize(in: generator.nsImage(for: "  trimmed payload  "))
        let exact = try recognizer.recognize(in: generator.nsImage(for: "trimmed payload"))

        #expect(padded.map(\.payload).contains("trimmed payload"))
        #expect(padded.map(\.payload) == exact.map(\.payload))
    }

    @MainActor
    @Test("History search finds content and source")
    func historySearchFindsContentAndSource() throws {
        let fileURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("history.json")
        let store = try QRHistoryStore(fileURL: fileURL)

        try store.add(content: "alpha payload", source: .typed, title: "First")
        try store.add(content: "beta payload", source: .clipboard)

        #expect(store.search("alpha").count == 1)
        #expect(store.search("clipboard").count == 1)
        #expect(store.search("").count == 2)
    }

    @MainActor
    @Test("History de-duplicates repeated content")
    func historyDeduplicatesRepeatedContent() throws {
        let fileURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("history.json")
        let store = try QRHistoryStore(fileURL: fileURL)

        try store.add(content: "same payload", source: .typed)
        try store.add(content: "same payload", source: .clipboard)

        #expect(store.records.count == 1)
        #expect(store.records.first?.source == .clipboard)
    }

    @MainActor
    @Test("History trims saved content and de-duplicates by trimmed value")
    func historyTrimsAndDeduplicatesContent() throws {
        let fileURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("history.json")
        let store = try QRHistoryStore(fileURL: fileURL)

        try store.add(content: "  trimmed payload  ", source: .typed)
        try store.add(content: "trimmed payload", source: .clipboard)

        #expect(store.records.count == 1)
        #expect(store.records.first?.content == "trimmed payload")
        #expect(store.records.first?.source == .clipboard)
    }
}
