import AppKit
import ApplicationServices
import Carbon.HIToolbox
import Foundation

@MainActor
final class SelectedTextService {
    var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityTrust() {
        let options = [
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func readSelectedText() async -> String? {
        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot.capture(from: pasteboard)
        let initialChangeCount = pasteboard.changeCount

        sendCopyShortcut()

        for _ in 0..<20 {
            try? await Task.sleep(nanoseconds: 50_000_000)

            guard pasteboard.changeCount != initialChangeCount else {
                continue
            }

            let content = pasteboard.string(forType: .string)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            snapshot.restore(to: pasteboard)
            return content?.isEmpty == false ? content : nil
        }

        snapshot.restore(to: pasteboard)
        return nil
    }

    private func sendCopyShortcut() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyCode = CGKeyCode(kVK_ANSI_C)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)

        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

private struct PasteboardSnapshot {
    private let items: [PasteboardItemSnapshot]

    static func capture(from pasteboard: NSPasteboard) -> PasteboardSnapshot {
        let items = pasteboard.pasteboardItems?.map(PasteboardItemSnapshot.init(item:)) ?? []
        return PasteboardSnapshot(items: items)
    }

    func restore(to pasteboard: NSPasteboard) {
        pasteboard.clearContents()

        let restoredItems = items.map { snapshot in
            let item = NSPasteboardItem()
            for (type, data) in snapshot.values {
                item.setData(data, forType: type)
            }
            return item
        }

        if !restoredItems.isEmpty {
            pasteboard.writeObjects(restoredItems)
        }
    }
}

private struct PasteboardItemSnapshot {
    let values: [(NSPasteboard.PasteboardType, Data)]

    init(item: NSPasteboardItem) {
        values = item.types.compactMap { type in
            guard let data = item.data(forType: type) else {
                return nil
            }

            return (type, data)
        }
    }
}
