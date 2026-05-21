import SwiftUI

@main
struct QRNativeApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 980, minHeight: 640)
        }
        .defaultSize(width: 980, height: 692)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Generate QR Code") {
                    appState.generateTyped()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(!appState.canGenerate)

                Button("Generate from Clipboard") {
                    appState.generateFromClipboard()
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])

                Button("Recognize Clipboard Image") {
                    appState.recognizeClipboardImage()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }

            CommandGroup(after: .textEditing) {
                Button("Focus Input") {
                    appState.focusInput()
                }
                .keyboardShortcut("l", modifiers: [.command])

                Button("Focus History Search") {
                    appState.focusSearch()
                }
                .keyboardShortcut("f", modifiers: [.command])
            }

            CommandGroup(after: .pasteboard) {
                Button("Copy QR Image") {
                    appState.copyGeneratedImage()
                }
                .keyboardShortcut("c", modifiers: [.command, .option])
                .disabled(appState.generatedImage == nil)

                Button("Copy QR Text") {
                    appState.copyInputText()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(appState.inputText.isEmpty)
            }

            CommandGroup(after: .saveItem) {
                Button("Save QR Code as PNG...") {
                    appState.saveGeneratedImage()
                }
                .keyboardShortcut("s", modifiers: [.command])
                .disabled(appState.generatedImage == nil)
            }

            CommandMenu("History") {
                Button("Delete Selected History Item") {
                    appState.deleteSelectedRecord()
                }
                .keyboardShortcut(.delete, modifiers: [])
                .disabled(appState.selectedRecord == nil)

                Button("Clear Input") {
                    appState.clearInput()
                }
                .keyboardShortcut("k", modifiers: [.command])
                .disabled(appState.inputText.isEmpty && appState.generatedImage == nil)
            }
        }
    }
}
