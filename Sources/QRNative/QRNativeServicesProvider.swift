import AppKit

@MainActor
final class QRNativeServicesProvider: NSObject {
    private weak var appState: AppState?

    init(appState: AppState) {
        self.appState = appState
    }

    @objc(generateQRCodeFromSelection:userData:error:)
    func generateQRCodeFromSelection(
        _ pasteboard: NSPasteboard,
        userData: String,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        guard let content = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty else {
            error.pointee = "QRNative could not read selected text."
            return
        }

        appState?.generateFromServiceText(content)
    }

    @objc(recognizeQRCodeFromSelection:userData:error:)
    func recognizeQRCodeFromSelection(
        _ pasteboard: NSPasteboard,
        userData: String,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        guard let image = image(from: pasteboard) else {
            error.pointee = "QRNative could not read selected image."
            return
        }

        appState?.recognizeFromServiceImage(image)
    }

    private func image(from pasteboard: NSPasteboard) -> NSImage? {
        if let image = NSImage(pasteboard: pasteboard) {
            return image
        }

        if let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] {
            for url in urls {
                if let image = NSImage(contentsOf: url) {
                    return image
                }
            }
        }

        return nil
    }
}

