import AppKit
import QRNativeCore
import SwiftUI

@MainActor
final class FloatingResultPresenter {
    private var panel: NSPanel?

    func showQRCode(image: NSImage, content: String) {
        let view = FloatingQRCodeView(image: image, content: content)
        show(rootView: view, size: NSSize(width: 380, height: 500))
    }

    func showRecognition(results: [RecognizedQRCode]) {
        let view = FloatingRecognitionView(results: results)
        show(rootView: view, size: NSSize(width: 380, height: 300))
    }

    private func show<Content: View>(rootView: Content, size: NSSize) {
        panel?.close()

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .utilityWindow, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "QRNative"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: rootView)
        panel.setFrameOrigin(origin(for: size))
        panel.orderFrontRegardless()

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
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "qrcode")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text("QR Code")
                        .font(.headline)
                    Text("Ready to share")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.62))

                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(18)
                    .frame(width: 272, height: 272)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.black.opacity(0.08), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
            }
            .frame(maxWidth: .infinity, minHeight: 304)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Content")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(content.count) chars")
                        .foregroundStyle(.tertiary)
                }
                .font(.caption)

                Text(content)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.70), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.separator.opacity(0.65), lineWidth: 1)
            }

            HStack(spacing: 8) {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.writeObjects([image])
                } label: {
                    Label("Copy Image", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(content, forType: .string)
                } label: {
                    Label("Copy Text", systemImage: "text.badge.checkmark")
                }
            }
            .controlSize(.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}

private struct FloatingRecognitionView: View {
    let results: [RecognizedQRCode]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text("Recognized QR Code")
                    .font(.headline)

                Spacer()
            }

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
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.70), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(.separator.opacity(0.65), lineWidth: 1)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}
