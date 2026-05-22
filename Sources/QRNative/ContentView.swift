import AppKit
import QRNativeCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        HStack(spacing: 0) {
            HistorySidebar()
                .frame(width: 300)

            Divider()

            WorkspaceView()
        }
        .background(WindowConfigurator())
        .alert("QRNative", isPresented: alertBinding) {
            Button("OK", role: .cancel) {
                state.alertMessage = nil
            }
        } message: {
            Text(state.alertMessage ?? "")
        }
        .onChange(of: state.selectedRecordID) { _ in
            state.loadSelectedRecord()
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { state.alertMessage != nil },
            set: { if !$0 { state.alertMessage = nil } }
        )
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(window: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(window: nsView.window)
        }
    }

    private func configure(window: NSWindow?) {
        guard let window else {
            return
        }

        window.title = "QRNative"
        window.minSize = NSSize(width: 980, height: 640)

        let visibleFrames = NSScreen.screens.map(\.visibleFrame)
        let isVisible = visibleFrames.contains { frame in
            frame.intersects(window.frame) && window.frame.midX >= frame.minX && window.frame.midX <= frame.maxX
        }

        if !isVisible, let screen = NSScreen.main {
            let size = NSSize(width: 980, height: 692)
            let frame = NSRect(
                x: screen.visibleFrame.midX - size.width / 2,
                y: screen.visibleFrame.midY - size.height / 2,
                width: size.width,
                height: size.height
            )
            window.setFrame(frame, display: true)
        }
    }
}

private struct HistorySidebar: View {
    @EnvironmentObject private var state: AppState
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("History", systemImage: "clock.arrow.circlepath")
                    .font(.headline)

                Spacer()

                Button {
                    state.generateFromClipboard()
                } label: {
                    Image(systemName: "doc.on.clipboard")
                }
                .help("Generate from clipboard")

                Button(role: .destructive) {
                    state.deleteSelectedRecord()
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(state.selectedRecord == nil)
                .help("Delete selected history item")
            }
            .padding([.horizontal, .top], 14)
            .padding(.bottom, 10)

            SearchField(text: $state.searchText)
                .focused($searchFocused)
                .padding(.horizontal, 14)
                .padding(.bottom, 10)

            if state.filteredRecords.isEmpty {
                EmptyStateView(
                    title: state.historyStore.records.isEmpty ? "No History" : "No Matches",
                    systemImage: "qrcode.viewfinder",
                    description: state.historyStore.records.isEmpty ? "Generated and recognized QR codes appear here." : "Try a different history search."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $state.selectedRecordID) {
                    ForEach(state.filteredRecords) { record in
                        HistoryRow(record: record)
                            .tag(record.id)
                            .contextMenu {
                                Button {
                                    state.generateRecord(record)
                                } label: {
                                    Label("Load", systemImage: "qrcode")
                                }

                                Button {
                                    state.copyRecordContent(record)
                                } label: {
                                    Label("Copy Text", systemImage: "doc.on.doc")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    state.deleteRecord(record)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Text("\(state.historyStore.records.count) item\(state.historyStore.records.count == 1 ? "" : "s")")
                Spacer()
                Text(state.hotKeyStatus)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .onChange(of: state.focusRequest) { request in
            if request == .search {
                searchFocused = true
            }
        }
    }
}

private struct HistoryRow: View {
    let record: QRCodeRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(record.displayTitle)
                .font(.callout)
                .lineLimit(2)

            HStack(spacing: 6) {
                Text(record.source.label)
                Text(record.createdAt, style: .date)
                Text(record.createdAt, style: .time)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search history", text: $text)
                .textFieldStyle(.plain)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct WorkspaceView: View {
    @EnvironmentObject private var state: AppState
    @State private var tab: WorkspaceTab = .generate

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Picker("Workspace", selection: $tab) {
                    ForEach(WorkspaceTab.allCases) { item in
                        Label(item.title, systemImage: item.symbol).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)

                Spacer()

                Text(state.statusMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(16)
            .background(.bar)

            Divider()

            switch tab {
            case .generate:
                GeneratorView()
            case .recognize:
                RecognizerView()
            }
        }
    }
}

private enum WorkspaceTab: CaseIterable, Identifiable {
    case generate
    case recognize

    var id: Self { self }

    var title: String {
        switch self {
        case .generate:
            return "Generate"
        case .recognize:
            return "Recognize"
        }
    }

    var symbol: String {
        switch self {
        case .generate:
            return "qrcode"
        case .recognize:
            return "viewfinder"
        }
    }
}

private struct GeneratorView: View {
    @EnvironmentObject private var state: AppState
    @FocusState private var inputFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Content")
                        .font(.headline)
                    Spacer()
                    Picker("Correction", selection: $state.correctionLevel) {
                        ForEach(QRCorrectionLevel.allCases) { level in
                            Text("\(level.label) \(level.detail)").tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 260)
                }

                TextEditor(text: $state.inputText)
                    .focused($inputFocused)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.separator)
                    }
                    .onChange(of: state.inputText) { _ in
                        state.schedulePreviewRefresh()
                    }
                    .onChange(of: state.correctionLevel) { _ in
                        state.refreshPreviewForCurrentInput()
                    }

                HStack {
                    Text("\(state.inputText.count) characters")
                    Text("\(state.inputByteCount) bytes")
                    Spacer()
                    if state.inputLooksLikeURL {
                        Button {
                            state.openInputURL()
                        } label: {
                            Label("Open URL", systemImage: "safari")
                        }
                        .labelStyle(.iconOnly)
                        .help("Open current URL")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack {
                    Button {
                        state.generateTyped()
                    } label: {
                        Label("Generate", systemImage: "qrcode")
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderedProminent)
                    .help("Generate QR code")
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(!state.canGenerate)

                    Button {
                        state.generateFromClipboard()
                    } label: {
                        Label("Clipboard", systemImage: "doc.on.clipboard")
                    }
                    .labelStyle(.iconOnly)
                    .help("Generate from clipboard")

                    Button {
                        state.copyInputText()
                    } label: {
                        Label("Copy Text", systemImage: "doc.on.doc")
                    }
                    .labelStyle(.iconOnly)
                    .help("Copy text")
                    .disabled(state.inputText.isEmpty)

                    Spacer()

                    Button(role: .destructive) {
                        state.clearInput()
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                    }
                    .labelStyle(.iconOnly)
                    .help("Clear")
                    .disabled(state.inputText.isEmpty && state.generatedImage == nil)
                }
            }
            .padding(18)
            .frame(minWidth: 380, idealWidth: 460, maxWidth: 520, maxHeight: .infinity)

            Divider()

            QRPreviewPane()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            inputFocused = true
        }
        .onChange(of: state.focusRequest) { request in
            if request == .input {
                inputFocused = true
            }
        }
    }
}

private struct QRPreviewPane: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Preview")
                    .font(.headline)
                Spacer()
                Button {
                    state.copyGeneratedImage()
                } label: {
                    Label("Copy Image", systemImage: "doc.on.doc")
                }
                .labelStyle(.iconOnly)
                .help("Copy QR image")
                .disabled(state.generatedImage == nil)

                Button {
                    state.saveGeneratedImage()
                } label: {
                    Label("Save PNG", systemImage: "square.and.arrow.down")
                }
                .labelStyle(.iconOnly)
                .help("Save PNG")
                .disabled(state.generatedImage == nil)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.05), radius: 12, y: 4)

                if let image = state.generatedImage {
                    Image(nsImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .padding(28)
                        .accessibilityLabel("Generated QR code")
                } else {
                    EmptyStateView(
                        title: "No QR Code",
                        systemImage: "qrcode",
                        description: "Enter text or use the clipboard shortcut."
                    )
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.separator)
            }
            .padding(.bottom, 4)
        }
        .padding(18)
    }
}

private struct RecognizerView: View {
    @EnvironmentObject private var state: AppState
    @State private var isDropTargeted = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Image")
                        .font(.headline)

                    Spacer()

                    Button {
                        state.importRecognitionImage()
                    } label: {
                        Label("Open Image", systemImage: "photo")
                    }

                    Button {
                        state.recognizeClipboardImage()
                    } label: {
                        Label("Paste Image", systemImage: "doc.on.clipboard")
                    }
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isDropTargeted ? Color.accentColor.opacity(0.12) : Color(nsColor: .textBackgroundColor))

                    if let image = state.selectedRecognitionImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding(18)
                            .accessibilityLabel("Image selected for QR recognition")
                    } else {
                        EmptyStateView(
                            title: "Drop an Image",
                            systemImage: "photo.badge.plus",
                            description: "Open, paste, or drag an image containing QR codes."
                        )
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isDropTargeted ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: isDropTargeted ? 2 : 1)
                }
                .onDrop(
                    of: [UTType.fileURL.identifier, UTType.image.identifier],
                    isTargeted: $isDropTargeted,
                    perform: state.handleDroppedProviders
                )

                Button(role: .destructive) {
                    state.clearRecognition()
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                }
                .disabled(state.selectedRecognitionImage == nil && state.recognizedResults.isEmpty)
            }
            .padding(18)
            .frame(minWidth: 380, idealWidth: 460, maxWidth: 520, maxHeight: .infinity)

            Divider()

            RecognitionResultsPane()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct RecognitionResultsPane: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Results")
                .font(.headline)

            if state.recognizedResults.isEmpty {
                EmptyStateView(
                    title: "No Results",
                    systemImage: "text.viewfinder",
                    description: "Recognized QR payloads appear here."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(state.recognizedResults) { result in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(result.payload)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)

                            HStack {
                                Text("Confidence \(Int(result.confidence * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Button {
                                    state.copyRecognizedPayload(result.payload)
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }

                                Button {
                                    state.openRecognizedURL(result.payload)
                                } label: {
                                    Label("Open", systemImage: "safari")
                                }

                                Button {
                                    state.useRecognizedPayload(result.payload)
                                } label: {
                                    Label("Generate", systemImage: "qrcode")
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding(18)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
