import AppKit
import QRNativeCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        TabView {
            GeneralSettingsPane()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            ShortcutSettingsPane()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            SelectionSettingsPane()
                .tabItem {
                    Label("Selection", systemImage: "cursorarrow.rays")
                }

            DataSettingsPane()
                .tabItem {
                    Label("Data", systemImage: "externaldrive")
                }

            AboutSettingsPane()
                .tabItem {
                    Label("About", systemImage: "app.badge")
                }
        }
        .environmentObject(appState)
        .environmentObject(settings)
        .frame(width: 640, height: 500)
    }
}

private struct GeneralSettingsPane: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Picker("Default correction", selection: $settings.defaultCorrectionLevel) {
                ForEach(QRCorrectionLevel.allCases) { level in
                    Text("\(level.label)  \(level.detail)").tag(level)
                }
            }

            Toggle("Refresh preview while typing", isOn: $settings.automaticPreview)

            Divider()

            Toggle("Save typed QR codes to history", isOn: $settings.saveTypedToHistory)
            Toggle("Save clipboard QR codes to history", isOn: $settings.saveClipboardToHistory)
            Toggle("Save recognized QR codes to history", isOn: $settings.saveRecognizedToHistory)
            Toggle("Save Services QR codes to history", isOn: $settings.saveServicesToHistory)

            HStack {
                Spacer()
                Button("Apply Default Correction") {
                    appState.applyDefaultCorrectionLevel()
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }
}

private struct ShortcutSettingsPane: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var isRecordingGlobalShortcut = false
    @State private var isRecordingSelectionShortcut = false
    @State private var isRecordingScreenshotShortcut = false

    var body: some View {
        Form {
            Toggle("Enable global clipboard shortcut", isOn: $settings.globalShortcutEnabled)
            Toggle("Enable selected text shortcut", isOn: $settings.selectionShortcutEnabled)
            Toggle("Enable screenshot QR shortcut", isOn: $settings.screenshotShortcutEnabled)
            Toggle("Bring QRNative to front after clipboard generation", isOn: $settings.bringToFrontAfterClipboard)

            Divider()

            ShortcutRow(title: "Generate QR code", shortcut: "⌘↩")
            ShortcutRow(title: "Generate from clipboard", shortcut: "⇧⌘V")
            EditableShortcutRow(
                title: "Global clipboard shortcut",
                shortcut: settings.globalShortcut.displayString,
                resetAction: {
                    settings.globalShortcut = .defaultClipboard
                },
                editAction: {
                    isRecordingGlobalShortcut = true
                }
            )
            EditableShortcutRow(
                title: "Selected text floating QR",
                shortcut: settings.selectionShortcut.displayString,
                resetAction: {
                    settings.selectionShortcut = .defaultSelection
                },
                editAction: {
                    isRecordingSelectionShortcut = true
                }
            )
            EditableShortcutRow(
                title: "Screenshot QR recognition",
                shortcut: settings.screenshotShortcut.displayString,
                resetAction: {
                    settings.screenshotShortcut = .defaultScreenshotRecognition
                },
                editAction: {
                    isRecordingScreenshotShortcut = true
                }
            )
            ShortcutRow(title: "Recognize clipboard image", shortcut: "⇧⌘R")
            ShortcutRow(title: "Copy QR image", shortcut: "⌥⌘C")
            ShortcutRow(title: "Copy QR text", shortcut: "⇧⌘C")
            ShortcutRow(title: "Save PNG", shortcut: "⌘S")
            ShortcutRow(title: "Delete selected history item", shortcut: "Delete")
            ShortcutRow(title: "Clear input", shortcut: "⌘K")
            ShortcutRow(title: "Focus input", shortcut: "⌘L")
            ShortcutRow(title: "Focus history search", shortcut: "⌘F")
        }
        .formStyle(.grouped)
        .padding(20)
        .sheet(isPresented: $isRecordingGlobalShortcut) {
            ShortcutRecorderSheet(shortcut: $settings.globalShortcut, defaultShortcut: .defaultClipboard)
        }
        .sheet(isPresented: $isRecordingSelectionShortcut) {
            ShortcutRecorderSheet(shortcut: $settings.selectionShortcut, defaultShortcut: .defaultSelection)
        }
        .sheet(isPresented: $isRecordingScreenshotShortcut) {
            ShortcutRecorderSheet(shortcut: $settings.screenshotShortcut, defaultShortcut: .defaultScreenshotRecognition)
        }
    }
}

private struct SelectionSettingsPane: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Use QRNative from any app")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("QRNative adds macOS Services for selected text and selected images. macOS keeps these off until you enable them once.")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    SystemSettingsOpener.openKeyboardShortcuts()
                } label: {
                    Label("Open Keyboard Shortcuts", systemImage: "arrow.up.forward.app")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    copyServiceNames()
                } label: {
                    Label("Copy Service Names", systemImage: "doc.on.doc")
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                ServiceSetupStep(
                    number: "1",
                    title: "Open Services",
                    detail: "In System Settings, choose Keyboard Shortcuts, then select Services in the left sidebar."
                )
                ServiceSetupStep(
                    number: "2",
                    title: "Enable text selection",
                    detail: "Expand Text and enable QRNative: Generate QR from Selected Text."
                )
                ServiceSetupStep(
                    number: "3",
                    title: "Enable image selection",
                    detail: "Expand Images and enable QRNative: Recognize QR in Selected Image."
                )
                ServiceSetupStep(
                    number: "4",
                    title: "Optional keyboard shortcuts",
                    detail: "Double-click None on the right side of either service, then press your shortcut."
                )
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("After setup")
                    .font(.headline)

                Label("Select text in any app, then Right Click > Services > QRNative: Generate QR from Selected Text.", systemImage: "text.cursor")
                Label("Select an image or image file, then Right Click > Services > QRNative: Recognize QR in Selected Image.", systemImage: "photo")
            }
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(20)
    }

    private func copyServiceNames() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(
            """
            QRNative: Generate QR from Selected Text
            QRNative: Recognize QR in Selected Image
            """,
            forType: .string
        )
    }
}

private struct ServiceSetupStep: View {
    let number: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .fontWeight(.semibold)
                Text(detail)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private enum SystemSettingsOpener {
    static func openKeyboardShortcuts() {
        let urls = [
            "x-apple.systempreferences:com.apple.Keyboard-Settings.extension?Shortcuts",
            "x-apple.systempreferences:com.apple.preference.keyboard?Shortcuts",
            "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"
        ]

        for value in urls {
            guard let url = URL(string: value) else {
                continue
            }

            if NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}

private struct ShortcutRow: View {
    let title: String
    let shortcut: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}

private struct EditableShortcutRow: View {
    let title: String
    let shortcut: String
    let resetAction: () -> Void
    let editAction: () -> Void

    var body: some View {
        HStack {
            Text(title)
            Spacer()

            Button(shortcut, action: editAction)
                .font(.system(.body, design: .monospaced))
                .help("Change shortcut")

            Button(action: resetAction) {
                Label("Reset shortcut", systemImage: "arrow.counterclockwise")
            }
            .labelStyle(.iconOnly)
            .help("Reset shortcut")
        }
    }
}

private struct ShortcutRecorderSheet: View {
    @Binding var shortcut: GlobalShortcut
    let defaultShortcut: GlobalShortcut
    @Environment(\.dismiss) private var dismiss
    @State private var message = "Press a key combination."

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Change Shortcut", systemImage: "keyboard")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
                .labelStyle(.iconOnly)
                .help("Cancel")
            }

            Text(message)
                .foregroundStyle(.secondary)

            Text(shortcut.displayString)
                .font(.system(size: 34, weight: .semibold, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

            ShortcutCaptureView { event in
                capture(event)
            }
            .frame(width: 1, height: 1)
            .accessibilityHidden(true)

            HStack {
                Button("Restore Default") {
                    shortcut = defaultShortcut
                    dismiss()
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private func capture(_ event: NSEvent) {
        if UInt32(event.keyCode) == GlobalShortcut.escapeKeyCode {
            dismiss()
            return
        }

        guard let nextShortcut = GlobalShortcut(event: event) else {
            message = "Use at least one modifier key."
            return
        }

        shortcut = nextShortcut
        dismiss()
    }
}

private struct ShortcutCaptureView: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Void

    func makeNSView(context: Context) -> ShortcutCaptureNSView {
        let view = ShortcutCaptureNSView(onKeyDown: onKeyDown)
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutCaptureNSView, context: Context) {
        nsView.onKeyDown = onKeyDown
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

private final class ShortcutCaptureNSView: NSView {
    var onKeyDown: (NSEvent) -> Void

    init(onKeyDown: @escaping (NSEvent) -> Void) {
        self.onKeyDown = onKeyDown
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        onKeyDown(event)
    }
}

private struct DataSettingsPane: View {
    @EnvironmentObject private var appState: AppState
    @State private var confirmsClearHistory = false

    var body: some View {
        Form {
            LabeledContent("History items") {
                Text("\(appState.historyStore.records.count)")
            }

            LabeledContent("History file") {
                Text(appState.historyFileURL.path)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }

            HStack {
                Button {
                    appState.revealHistoryFile()
                } label: {
                    Label("Reveal in Finder", systemImage: "folder")
                }

                Button {
                    appState.openApplicationSupportFolder()
                } label: {
                    Label("Open Folder", systemImage: "externaldrive")
                }

                Spacer()

                Button(role: .destructive) {
                    confirmsClearHistory = true
                } label: {
                    Label("Clear History", systemImage: "trash")
                }
                .disabled(appState.historyStore.records.isEmpty)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .alert("Clear History?", isPresented: $confirmsClearHistory) {
            Button("Cancel", role: .cancel) {}
            Button("Clear History", role: .destructive) {
                appState.deleteAllHistory()
            }
        } message: {
            Text("This removes all saved QR records from local history.")
        }
    }
}

private struct AboutSettingsPane: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("QRNative")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Native macOS QR utility")
                        .foregroundStyle(.secondary)
                }
            }

            Text("QRNative keeps QR generation, recognition, and history local on this Mac.")
                .foregroundStyle(.secondary)

            Divider()

            Button("Reset Settings") {
                settings.reset()
            }

            Spacer()
        }
        .padding(24)
    }

    private var appIcon: NSImage {
        NSApp.applicationIconImage ?? NSImage(systemSymbolName: "qrcode", accessibilityDescription: nil) ?? NSImage()
    }
}
