import AppKit
import QRNativeCore
import SwiftUI

struct MenuBarHistoryView: View {
    @EnvironmentObject private var state: AppState

    private let maxItems = 12

    var body: some View {
        let records = state.historyStore.records

        if records.isEmpty {
            Text("No History Yet")
        } else {
            Section("Recent QR Codes") {
                ForEach(records.prefix(maxItems)) { record in
                    Button(menuLabel(for: record)) {
                        state.presentHistoryQRCode(record)
                    }
                }
            }
        }

        Divider()

        Button("Open QRNative") {
            state.activateMainWindow()
        }

        Button("Clear History") {
            state.deleteAllHistory()
        }
        .disabled(records.isEmpty)

        Divider()

        Button("Quit QRNative") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func menuLabel(for record: QRCodeRecord) -> String {
        let title = record.displayTitle.replacingOccurrences(of: "\n", with: " ")
        guard title.count > 45 else {
            return title
        }

        return String(title.prefix(44)) + "…"
    }
}
