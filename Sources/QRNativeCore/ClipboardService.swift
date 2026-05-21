import AppKit
import Foundation

public struct ClipboardService: Sendable {
    public init() {}

    public func readString() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    public func readImage() -> NSImage? {
        let pasteboard = NSPasteboard.general
        if let image = NSImage(pasteboard: pasteboard) {
            return image
        }

        if let data = pasteboard.data(forType: .tiff), let image = NSImage(data: data) {
            return image
        }

        if let data = pasteboard.data(forType: .png), let image = NSImage(data: data) {
            return image
        }

        return nil
    }

    public func writeString(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    public func writeImage(_ image: NSImage) -> Bool {
        NSPasteboard.general.clearContents()
        return NSPasteboard.general.writeObjects([image])
    }
}

