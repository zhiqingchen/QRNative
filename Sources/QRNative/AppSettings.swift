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
        static let saveServicesToHistory = "saveServicesToHistory"
        static let bringToFrontAfterClipboard = "bringToFrontAfterClipboard"
        static let globalShortcutEnabled = "globalShortcutEnabled"
        static let globalShortcutKeyCode = "globalShortcutKeyCode"
        static let globalShortcutModifiers = "globalShortcutModifiers"
        static let selectionShortcutEnabled = "selectionShortcutEnabled"
        static let selectionShortcutKeyCode = "selectionShortcutKeyCode"
        static let selectionShortcutModifiers = "selectionShortcutModifiers"
        static let screenshotShortcutEnabled = "screenshotShortcutEnabled"
        static let screenshotShortcutKeyCode = "screenshotShortcutKeyCode"
        static let screenshotShortcutModifiers = "screenshotShortcutModifiers"
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

    @Published var saveServicesToHistory: Bool {
        didSet { defaults.set(saveServicesToHistory, forKey: Key.saveServicesToHistory) }
    }

    @Published var bringToFrontAfterClipboard: Bool {
        didSet { defaults.set(bringToFrontAfterClipboard, forKey: Key.bringToFrontAfterClipboard) }
    }

    @Published var globalShortcutEnabled: Bool {
        didSet { defaults.set(globalShortcutEnabled, forKey: Key.globalShortcutEnabled) }
    }

    @Published var globalShortcut: GlobalShortcut {
        didSet {
            defaults.set(Int(globalShortcut.keyCode), forKey: Key.globalShortcutKeyCode)
            defaults.set(Int(globalShortcut.carbonModifiers), forKey: Key.globalShortcutModifiers)
        }
    }

    @Published var selectionShortcutEnabled: Bool {
        didSet { defaults.set(selectionShortcutEnabled, forKey: Key.selectionShortcutEnabled) }
    }

    @Published var selectionShortcut: GlobalShortcut {
        didSet {
            defaults.set(Int(selectionShortcut.keyCode), forKey: Key.selectionShortcutKeyCode)
            defaults.set(Int(selectionShortcut.carbonModifiers), forKey: Key.selectionShortcutModifiers)
        }
    }

    @Published var screenshotShortcutEnabled: Bool {
        didSet { defaults.set(screenshotShortcutEnabled, forKey: Key.screenshotShortcutEnabled) }
    }

    @Published var screenshotShortcut: GlobalShortcut {
        didSet {
            defaults.set(Int(screenshotShortcut.keyCode), forKey: Key.screenshotShortcutKeyCode)
            defaults.set(Int(screenshotShortcut.carbonModifiers), forKey: Key.screenshotShortcutModifiers)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let rawLevel = defaults.string(forKey: Key.defaultCorrectionLevel) ?? QRCorrectionLevel.medium.rawValue
        let storedGlobalShortcut: GlobalShortcut
        if
            let rawKeyCode = defaults.object(forKey: Key.globalShortcutKeyCode) as? Int,
            let rawModifiers = defaults.object(forKey: Key.globalShortcutModifiers) as? Int,
            rawModifiers != 0
        {
            storedGlobalShortcut = GlobalShortcut(
                keyCode: UInt32(rawKeyCode),
                carbonModifiers: UInt32(rawModifiers)
            )
        } else {
            storedGlobalShortcut = .defaultClipboard
        }

        let storedSelectionShortcut: GlobalShortcut
        if
            let rawKeyCode = defaults.object(forKey: Key.selectionShortcutKeyCode) as? Int,
            let rawModifiers = defaults.object(forKey: Key.selectionShortcutModifiers) as? Int,
            rawModifiers != 0
        {
            storedSelectionShortcut = GlobalShortcut(
                keyCode: UInt32(rawKeyCode),
                carbonModifiers: UInt32(rawModifiers)
            )
        } else {
            storedSelectionShortcut = .defaultSelection
        }

        let storedScreenshotShortcut: GlobalShortcut
        if
            let rawKeyCode = defaults.object(forKey: Key.screenshotShortcutKeyCode) as? Int,
            let rawModifiers = defaults.object(forKey: Key.screenshotShortcutModifiers) as? Int,
            rawModifiers != 0
        {
            storedScreenshotShortcut = GlobalShortcut(
                keyCode: UInt32(rawKeyCode),
                carbonModifiers: UInt32(rawModifiers)
            )
        } else {
            storedScreenshotShortcut = .defaultScreenshotRecognition
        }

        self.defaultCorrectionLevel = QRCorrectionLevel(rawValue: rawLevel) ?? .medium
        self.automaticPreview = defaults.object(forKey: Key.automaticPreview) as? Bool ?? true
        self.saveTypedToHistory = defaults.object(forKey: Key.saveTypedToHistory) as? Bool ?? true
        self.saveClipboardToHistory = defaults.object(forKey: Key.saveClipboardToHistory) as? Bool ?? true
        self.saveRecognizedToHistory = defaults.object(forKey: Key.saveRecognizedToHistory) as? Bool ?? true
        self.saveServicesToHistory = defaults.object(forKey: Key.saveServicesToHistory) as? Bool ?? true
        self.bringToFrontAfterClipboard = defaults.object(forKey: Key.bringToFrontAfterClipboard) as? Bool ?? false
        self.globalShortcutEnabled = defaults.object(forKey: Key.globalShortcutEnabled) as? Bool ?? true
        self.globalShortcut = storedGlobalShortcut
        self.selectionShortcutEnabled = defaults.object(forKey: Key.selectionShortcutEnabled) as? Bool ?? true
        self.selectionShortcut = storedSelectionShortcut
        self.screenshotShortcutEnabled = defaults.object(forKey: Key.screenshotShortcutEnabled) as? Bool ?? true
        self.screenshotShortcut = storedScreenshotShortcut
    }

    func reset() {
        defaultCorrectionLevel = .medium
        automaticPreview = true
        saveTypedToHistory = true
        saveClipboardToHistory = true
        saveRecognizedToHistory = true
        saveServicesToHistory = true
        bringToFrontAfterClipboard = false
        globalShortcutEnabled = true
        globalShortcut = .defaultClipboard
        selectionShortcutEnabled = true
        selectionShortcut = .defaultSelection
        screenshotShortcutEnabled = true
        screenshotShortcut = .defaultScreenshotRecognition
    }
}
