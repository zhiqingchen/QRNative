import Foundation
import QRNativeCore

@MainActor
final class AppSettings: ObservableObject {
    private enum Key {
        static let defaultCorrectionLevel = "defaultCorrectionLevel"
        static let automaticPreview = "automaticPreview"
        static let saveTypedToHistory = "saveTypedToHistory"
        static let saveClipboardToHistory = "saveClipboardToHistory"
        static let saveRecognizedToHistory = "saveRecognizedToHistory"
        static let bringToFrontAfterClipboard = "bringToFrontAfterClipboard"
        static let globalShortcutEnabled = "globalShortcutEnabled"
    }

    private let defaults: UserDefaults

    @Published var defaultCorrectionLevel: QRCorrectionLevel {
        didSet { defaults.set(defaultCorrectionLevel.rawValue, forKey: Key.defaultCorrectionLevel) }
    }

    @Published var automaticPreview: Bool {
        didSet { defaults.set(automaticPreview, forKey: Key.automaticPreview) }
    }

    @Published var saveTypedToHistory: Bool {
        didSet { defaults.set(saveTypedToHistory, forKey: Key.saveTypedToHistory) }
    }

    @Published var saveClipboardToHistory: Bool {
        didSet { defaults.set(saveClipboardToHistory, forKey: Key.saveClipboardToHistory) }
    }

    @Published var saveRecognizedToHistory: Bool {
        didSet { defaults.set(saveRecognizedToHistory, forKey: Key.saveRecognizedToHistory) }
    }

    @Published var bringToFrontAfterClipboard: Bool {
        didSet { defaults.set(bringToFrontAfterClipboard, forKey: Key.bringToFrontAfterClipboard) }
    }

    @Published var globalShortcutEnabled: Bool {
        didSet { defaults.set(globalShortcutEnabled, forKey: Key.globalShortcutEnabled) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let rawLevel = defaults.string(forKey: Key.defaultCorrectionLevel) ?? QRCorrectionLevel.medium.rawValue
        self.defaultCorrectionLevel = QRCorrectionLevel(rawValue: rawLevel) ?? .medium
        self.automaticPreview = defaults.object(forKey: Key.automaticPreview) as? Bool ?? true
        self.saveTypedToHistory = defaults.object(forKey: Key.saveTypedToHistory) as? Bool ?? true
        self.saveClipboardToHistory = defaults.object(forKey: Key.saveClipboardToHistory) as? Bool ?? true
        self.saveRecognizedToHistory = defaults.object(forKey: Key.saveRecognizedToHistory) as? Bool ?? true
        self.bringToFrontAfterClipboard = defaults.object(forKey: Key.bringToFrontAfterClipboard) as? Bool ?? true
        self.globalShortcutEnabled = defaults.object(forKey: Key.globalShortcutEnabled) as? Bool ?? true
    }

    func reset() {
        defaultCorrectionLevel = .medium
        automaticPreview = true
        saveTypedToHistory = true
        saveClipboardToHistory = true
        saveRecognizedToHistory = true
        bringToFrontAfterClipboard = true
        globalShortcutEnabled = true
    }
}

