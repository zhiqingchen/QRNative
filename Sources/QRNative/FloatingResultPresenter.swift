import AppKit
import QRNativeCore
import SwiftUI

@MainActor
final class FloatingResultPresenter {
    private var panel: NSPanel?

    func showQRCode(image: NSImage, content: String) {
        let view = FloatingQRCodeView(image: image, content: content)
        show(rootView: view, size: NSSize(width: 320, height: 410))
    }

    func showRecognition(results: [RecognizedQRCode]) {
        let view = FloatingRecognitionView(results: results)
        show(rootView: view, size: NSSize(width: 380, height: 300))
    }

    private func show<Content: View>(rootView: Content, size: NSSize) {
        panel?.close()

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .utilityWindow, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "QRNative"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: rootView)
        panel.setFrameOrigin(origin(for: size))
        panel.makeKeyAndOrderFront(nil)

        self.panel = panel
    }

    private func origin(for size: NSSize) -> NSPoint {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.visibleFrame.contains(mouse) } ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        var origin = NSPoint(x: mouse.x + 18, y: mouse.y - size.height - 18)

        if origin.x + size.width > visibleFrame.maxX {
            origin.x = mouse.x - size.width - 18
        }

        if origin.y < visibleFrame.minY {
            origin.y = mouse.y + 18
        }

        origin.x = min(max(origin.x, visibleFrame.minX + 12), visibleFrame.maxX - size.width - 12)
        origin.y = min(max(origin.y, visibleFrame.minY + 12), visibleFrame.maxY - size.height - 12)

        return origin
    }
}

private struct FloatingQRCodeView: View {
    let image: NSImage
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("QR Code", systemImage: "qrcode")
                    .font(.headline)
                Spacer()
            }

            Image(nsImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .padding(14)
                .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.separator)
                }

            Text(content)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(3)
                .truncationMode(.middle)
                .textSelection(.enabled)

            HStack {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.writeObjects([image])
                } label: {
                    Label("Copy Image", systemImage: "doc.on.doc")
                }

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(content, forType: .string)
                } label: {
                    Label("Copy Text", systemImage: "text.badge.checkmark")
                }
            }
        }
        .padding(16)
    }
}

private struct FloatingRecognitionView: View {
    let results: [RecognizedQRCode]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recognized QR Code", systemImage: "viewfinder")
                .font(.headline)

            if results.isEmpty {
                ContentUnavailableView(
                    "No QR Code Found",
                    systemImage: "qrcode.viewfinder",
                    description: Text("Try a clearer image or a larger selection.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(results) { result in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(result.payload)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)

                                HStack {
                                    Text("\(Int(result.confidence * 100))% confidence")
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    Button {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(result.payload, forType: .string)
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                    }
                                    .help("Copy")

                                    Button {
                                        if let url = URL(string: result.payload) {
                                            NSWorkspace.shared.open(url)
                                        }
                                    } label: {
                                        Image(systemName: "safari")
                                    }
                                    .help("Open URL")
                                }
                                .font(.caption)
                            }
                            .padding(10)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }
            }
        }
        .padding(16)
    }
}

