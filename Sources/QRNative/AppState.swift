import AppKit
import Combine
import QRNativeCore
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class AppState: ObservableObject {
    @Published var inputText: String = ""
    @Published var correctionLevel: QRCorrectionLevel = .medium
    @Published var generatedImage: NSImage?
    @Published var selectedRecordID: QRCodeRecord.ID?
    @Published var searchText: String = ""
    @Published var recognizedResults: [RecognizedQRCode] = []
    @Published var selectedRecognitionImage: NSImage?
    @Published var statusMessage: String = "Ready"
    @Published var alertMessage: String?
    @Published var hotKeyStatus: String = "Global shortcuts: registering..."
    @Published var focusRequest: FocusRequest?

    let historyStore: QRHistoryStore
    let settings: AppSettings

    private let generator = QRCodeGenerator()
    private let recognizer = QRRecognizer()
    private let clipboard = ClipboardService()
    private let selectedTextService = SelectedTextService()
    private let screenshotCaptureService = ScreenshotCaptureService()
    private let floatingPresenter = FloatingResultPresenter()
    private var hotKeyManager: GlobalHotKeyManager?
    private var selectionHotKeyManager: GlobalHotKeyManager?
    private var screenshotHotKeyManager: GlobalHotKeyManager?
    private var servicesProvider: QRNativeServicesProvider?
    private var cancellables = Set<AnyCancellable>()
    private var previewTask: Task<Void, Never>?
    private var clipboardHotKeyStatus = "Clipboard: registering..."
    private var selectionHotKeyStatus = "Selection: registering..."
    private var screenshotHotKeyStatus = "Screenshot: registering..."

    enum FocusRequest: Equatable {
        case input
        case search
    }

    var filteredRecords: [QRCodeRecord] {
        historyStore.search(searchText)
    }

    var canGenerate: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var selectedRecord: QRCodeRecord? {
        guard let selectedRecordID else {
            return nil
        }

        return historyStore.records.first { $0.id == selectedRecordID }
    }

    var inputByteCount: Int {
        inputText.data(using: .utf8)?.count ?? 0
    }

    var inputLooksLikeURL: Bool {
        guard let url = URL(string: inputText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return false
        }

        return url.scheme == "http" || url.scheme == "https"
    }

    init(settings: AppSettings = AppSettings()) {
        self.settings = settings
        self.correctionLevel = settings.defaultCorrectionLevel

        do {
            historyStore = try QRHistoryStore()
        } catch {
            let fallbackURL = FileManager.default
                .temporaryDirectory
                .appendingPathComponent("QRNative-history.json")
            historyStore = try! QRHistoryStore(fileURL: fallbackURL)
            alertMessage = "History is using a temporary file: \(error.localizedDescription)"
        }

        historyStore.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        settings.$globalShortcutEnabled
            .dropFirst()
            .sink { [weak self] _ in
                self?.updateGlobalHotKeyRegistration()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        settings.$globalShortcut
            .dropFirst()
            .sink { [weak self] _ in
                self?.updateGlobalHotKeyRegistration()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        settings.$selectionShortcutEnabled
            .dropFirst()
            .sink { [weak self] _ in
                self?.updateSelectionHotKeyRegistration()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        settings.$selectionShortcut
            .dropFirst()
            .sink { [weak self] _ in
                self?.updateSelectionHotKeyRegistration()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        settings.$screenshotShortcutEnabled
            .dropFirst()
            .sink { [weak self] _ in
                self?.updateScreenshotHotKeyRegistration()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        settings.$screenshotShortcut
            .dropFirst()
            .sink { [weak self] _ in
                self?.updateScreenshotHotKeyRegistration()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        settings.$automaticPreview
            .dropFirst()
            .sink { [weak self] enabled in
                if enabled {
                    self?.schedulePreviewRefresh()
                }
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        updateGlobalHotKeyRegistration()
        updateSelectionHotKeyRegistration()
        updateScreenshotHotKeyRegistration()
        installServicesProvider()
    }

    func generateTyped() {
        generate(content: inputText, source: .typed, saveToHistory: settings.saveTypedToHistory)
    }

    func generateFromClipboard() {
        guard let content = clipboard.readString()?.trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty else {
            showAlert("Clipboard does not contain text.")
            return
        }

        inputText = content
        generate(content: content, source: .clipboard, saveToHistory: settings.saveClipboardToHistory)

        if let generatedImage {
            floatingPresenter.showQRCode(image: generatedImage, content: content)
        }

        if settings.bringToFrontAfterClipboard {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func generate(content: String, source: QRRecordSource, saveToHistory: Bool) {
        do {
            generatedImage = try generator.nsImage(for: content, correctionLevel: correctionLevel, sideLength: 900)
            statusMessage = saveToHistory ? "Saved \(source.label.lowercased()) QR code" : "Preview updated"

            if saveToHistory {
                let record = try historyStore.add(content: content, source: source, correctionLevel: correctionLevel)
                selectedRecordID = record.id
            }
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    func generateFromServiceText(_ content: String) {
        do {
            correctionLevel = settings.defaultCorrectionLevel
            let image = try generator.nsImage(for: content, correctionLevel: correctionLevel, sideLength: 900)
            inputText = content
            generatedImage = image
            statusMessage = "Generated service QR code"

            if settings.saveServicesToHistory {
                let record = try historyStore.add(content: content, source: .service, correctionLevel: correctionLevel)
                selectedRecordID = record.id
            }

            floatingPresenter.showQRCode(image: image, content: content)
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    func generateFloatingQRCodeFromSelectedText() {
        guard selectedTextService.isAccessibilityTrusted else {
            selectedTextService.requestAccessibilityTrust()
            selectedTextService.openAccessibilitySettings()
            statusMessage = "Enable QRNative in Privacy & Security > Accessibility, then try the shortcut again."
            return
        }

        Task { [weak self] in
            guard let self else {
                return
            }

            guard let content = await selectedTextService.readSelectedText() else {
                showAlert("Could not read selected text. You can also enable the QRNative Services shortcut in System Settings.")
                return
            }

            generateFromServiceText(content)
        }
    }

    func recognizeQRCodeFromScreenshot() {
        statusMessage = "Select a screenshot area"

        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                guard let data = try await screenshotCaptureService.captureInteractivePNGData() else {
                    statusMessage = "Screenshot canceled"
                    return
                }

                guard let image = NSImage(data: data) else {
                    showAlert("Unable to read the screenshot.")
                    return
                }

                recognizeScreenshot(image)
            } catch {
                showAlert(error.localizedDescription)
            }
        }
    }

    func presentHistoryQRCode(_ record: QRCodeRecord) {
        do {
            let image = try generator.nsImage(for: record.content, correctionLevel: record.correctionLevel, sideLength: 900)
            floatingPresenter.showQRCode(image: image, content: record.content)
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    func activateMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.canBecomeMain {
            window.makeKeyAndOrderFront(nil)
            return
        }
    }

    func loadSelectedRecord() {
        guard let record = selectedRecord else {
            return
        }

        guard record.content != inputText || record.correctionLevel != correctionLevel || generatedImage == nil else {
            return
        }

        inputText = record.content
        correctionLevel = record.correctionLevel
        generate(content: record.content, source: record.source, saveToHistory: false)
        statusMessage = "Loaded history item"
    }

    func copyGeneratedImage() {
        guard let generatedImage else {
            showAlert("Generate a QR code first.")
            return
        }

        if clipboard.writeImage(generatedImage) {
            statusMessage = "Copied QR image"
        } else {
            showAlert("Unable to copy the QR image.")
        }
    }

    func copyInputText() {
        guard !inputText.isEmpty else {
            return
        }

        clipboard.writeString(inputText)
        statusMessage = "Copied text"
    }

    func copyRecordContent(_ record: QRCodeRecord) {
        clipboard.writeString(record.content)
        statusMessage = "Copied history item"
    }

    func generateRecord(_ record: QRCodeRecord) {
        selectedRecordID = record.id
        inputText = record.content
        correctionLevel = record.correctionLevel
        generate(content: record.content, source: record.source, saveToHistory: false)
        statusMessage = "Loaded history item"
    }

    func deleteRecord(_ record: QRCodeRecord) {
        do {
            try historyStore.delete(record)
            if selectedRecordID == record.id {
                selectedRecordID = nil
            }
            statusMessage = "Deleted history item"
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    func saveGeneratedImage() {
        guard canGenerate else {
            showAlert("Generate a QR code first.")
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = defaultExportName(for: inputText)

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let data = try generator.pngData(for: inputText, correctionLevel: correctionLevel, sideLength: 1200)
            try data.write(to: url, options: [.atomic])
            statusMessage = "Saved \(url.lastPathComponent)"
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    func deleteSelectedRecord() {
        guard let record = selectedRecord else {
            return
        }

        deleteRecord(record)
    }

    func refreshPreviewForCurrentInput() {
        guard canGenerate else {
            generatedImage = nil
            return
        }

        do {
            generatedImage = try generator.nsImage(for: inputText, correctionLevel: correctionLevel, sideLength: 900)
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    func schedulePreviewRefresh() {
        previewTask?.cancel()

        guard settings.automaticPreview else {
            return
        }

        guard canGenerate else {
            generatedImage = nil
            statusMessage = "Ready"
            return
        }

        previewTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                self?.refreshPreviewForCurrentInput()
            }
        }
    }

    func focusInput() {
        focusRequest = .input
    }

    func focusSearch() {
        focusRequest = .search
    }

    func openInputURL() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), NSWorkspace.shared.open(url) else {
            showAlert("Current text is not an openable URL.")
            return
        }

        statusMessage = "Opened URL"
    }

    func clearInput() {
        inputText = ""
        generatedImage = nil
        selectedRecordID = nil
        statusMessage = "Cleared"
    }

    func deleteAllHistory() {
        do {
            try historyStore.deleteAll()
            selectedRecordID = nil
            statusMessage = "Cleared history"
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    var historyFileURL: URL {
        historyStore.storageURL
    }

    func revealHistoryFile() {
        let url = historyFileURL
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            openApplicationSupportFolder()
        }
    }

    func openApplicationSupportFolder() {
        let folder = historyFileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        NSWorkspace.shared.open(folder)
    }

    func importRecognitionImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        recognizeImage(at: url)
    }

    func recognizeImage(at url: URL) {
        guard let image = NSImage(contentsOf: url) else {
            showAlert("Unable to open image.")
            return
        }

        recognize(image: image, sourceName: url.lastPathComponent)
    }

    func recognizeClipboardImage() {
        guard let image = clipboard.readImage() else {
            showAlert("Clipboard does not contain an image.")
            return
        }

        recognize(image: image, sourceName: "clipboard image")
        NSApp.activate(ignoringOtherApps: true)
    }

    func recognize(image: NSImage, sourceName: String) {
        do {
            selectedRecognitionImage = image
            recognizedResults = try recognizer.recognize(in: image)

            if recognizedResults.isEmpty {
                statusMessage = "No QR code found in \(sourceName)"
            } else {
                statusMessage = "Recognized \(recognizedResults.count) QR code(s)"
            }
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    func recognizeFromServiceImage(_ image: NSImage) {
        do {
            selectedRecognitionImage = image
            recognizedResults = try recognizer.recognize(in: image)
            statusMessage = recognizedResults.isEmpty ? "No QR code found in service image" : "Recognized \(recognizedResults.count) service QR code(s)"
            floatingPresenter.showRecognition(results: recognizedResults)
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    func recognizeScreenshot(_ image: NSImage) {
        do {
            selectedRecognitionImage = image
            recognizedResults = try recognizer.recognize(in: image)
            floatingPresenter.showRecognition(results: recognizedResults)

            if let payload = recognizedResults.first?.payload {
                clipboard.writeString(payload)
                statusMessage = "Recognized screenshot QR code and copied text"
            } else {
                statusMessage = "No QR code found in screenshot"
            }
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    func useRecognizedPayload(_ payload: String) {
        inputText = payload
        generate(content: payload, source: .recognized, saveToHistory: settings.saveRecognizedToHistory)
    }

    func copyRecognizedPayload(_ payload: String) {
        clipboard.writeString(payload)
        statusMessage = "Copied recognized text"
    }

    func openRecognizedURL(_ payload: String) {
        guard let url = URL(string: payload), NSWorkspace.shared.open(url) else {
            showAlert("This result is not an openable URL.")
            return
        }

        statusMessage = "Opened URL"
    }

    func clearRecognition() {
        selectedRecognitionImage = nil
        recognizedResults = []
        statusMessage = "Recognition cleared"
    }

    func handleDroppedProviders(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] item, _ in
                    let url: URL?
                    if let data = item as? Data {
                        url = URL(dataRepresentation: data, relativeTo: nil)
                    } else {
                        url = item as? URL
                    }

                    guard let url else {
                        return
                    }

                    Task { @MainActor in
                        self?.recognizeImage(at: url)
                    }
                }
                return true
            }

            if provider.canLoadObject(ofClass: NSImage.self) {
                provider.loadObject(ofClass: NSImage.self) { [weak self] image, _ in
                    guard let image = image as? NSImage,
                          let imageData = image.tiffRepresentation else {
                        return
                    }

                    Task { @MainActor in
                        guard let restoredImage = NSImage(data: imageData) else {
                            return
                        }
                        self?.recognize(image: restoredImage, sourceName: "dropped image")
                    }
                }
                return true
            }
        }

        return false
    }

    func applyDefaultCorrectionLevel() {
        correctionLevel = settings.defaultCorrectionLevel
        refreshPreviewForCurrentInput()
        statusMessage = "Applied default correction"
    }

    private func updateGlobalHotKeyRegistration() {
        hotKeyManager?.unregister()
        hotKeyManager = nil

        guard settings.globalShortcutEnabled else {
            clipboardHotKeyStatus = "Clipboard: off"
            refreshHotKeyStatus()
            return
        }

        let manager = GlobalHotKeyManager { [weak self] in
            self?.generateFromClipboard()
        }

        if manager.register(shortcut: settings.globalShortcut) {
            clipboardHotKeyStatus = "Clipboard: \(settings.globalShortcut.displayString)"
            hotKeyManager = manager
        } else {
            clipboardHotKeyStatus = "Clipboard shortcut unavailable"
        }

        refreshHotKeyStatus()
    }

    private func updateSelectionHotKeyRegistration() {
        selectionHotKeyManager?.unregister()
        selectionHotKeyManager = nil

        guard settings.selectionShortcutEnabled else {
            selectionHotKeyStatus = "Selection: off"
            refreshHotKeyStatus()
            return
        }

        let manager = GlobalHotKeyManager { [weak self] in
            self?.generateFloatingQRCodeFromSelectedText()
        }

        if manager.register(shortcut: settings.selectionShortcut) {
            selectionHotKeyStatus = "Selection: \(settings.selectionShortcut.displayString)"
            selectionHotKeyManager = manager
        } else {
            selectionHotKeyStatus = "Selection shortcut unavailable"
        }

        refreshHotKeyStatus()
    }

    private func updateScreenshotHotKeyRegistration() {
        screenshotHotKeyManager?.unregister()
        screenshotHotKeyManager = nil

        guard settings.screenshotShortcutEnabled else {
            screenshotHotKeyStatus = "Screenshot: off"
            refreshHotKeyStatus()
            return
        }

        let manager = GlobalHotKeyManager { [weak self] in
            self?.recognizeQRCodeFromScreenshot()
        }

        if manager.register(shortcut: settings.screenshotShortcut) {
            screenshotHotKeyStatus = "Screenshot: \(settings.screenshotShortcut.displayString)"
            screenshotHotKeyManager = manager
        } else {
            screenshotHotKeyStatus = "Screenshot shortcut unavailable"
        }

        refreshHotKeyStatus()
    }

    private func refreshHotKeyStatus() {
        hotKeyStatus = "\(clipboardHotKeyStatus) · \(selectionHotKeyStatus) · \(screenshotHotKeyStatus)"
    }

    private func installServicesProvider() {
        let provider = QRNativeServicesProvider(appState: self)
        servicesProvider = provider
        NSApp.servicesProvider = provider
        NSUpdateDynamicServices()
    }

    private func defaultExportName(for content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "QRNative" : String(trimmed.prefix(32))
        let safe = base
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        return "\(safe.isEmpty ? "QRNative" : safe).png"
    }

    private func showAlert(_ message: String) {
        alertMessage = message
        statusMessage = message
    }
}
