# QRNative TODO

## 0. Project Initialization

- [x] Create Swift Package project scaffold for a native macOS SwiftUI app.
- [x] Add a minimal SwiftUI app entry point and placeholder main window.
- [x] Add repository ignore rules for SwiftPM, Xcode, and macOS generated files.
- [x] Add README with project purpose and development command.
- [x] Decide app display name, bundle identifier, icon direction, and minimum supported macOS version.
- [x] Decide whether to keep Swift Package only or add an Xcode project/app bundle workflow.
- [x] Add AGENTS.md collaboration guide.
- [x] Add app bundle script.
- [x] Add app icon and brand assets.

## 1. Text to QR Code

- [x] Build main window layout with text input, QR preview, and export/copy actions.
- [x] Generate QR code images from typed text using Core Image `CIQRCodeGenerator`.
- [x] Add QR correction level selection: L, M, Q, H.
- [x] Add preview scaling that stays crisp on Retina displays.
- [x] Add actions to copy QR image, save PNG, and clear input.
- [x] Handle empty text, very long text, and unsupported input states gracefully.
- [x] Add automatic preview refresh while typing without saving to history.

## 2. QR History

- [x] Define `QRCodeRecord` model with id, content, created date, source, preview image metadata, and optional title.
- [x] Choose persistence approach: SwiftData, Core Data, or local JSON/SQLite.
- [x] Save generated QR records automatically or through an explicit toggle.
- [x] Build history sidebar/list.
- [x] Add search by content/title with instant filtering.
- [x] Add record detail flow with regenerate, copy content, copy image, export image, and delete actions.
- [x] Add duplicate handling policy for repeated clipboard/text entries.
- [x] Add context menu actions for loading, copying, and deleting history records.
- [ ] Add explicit date grouping headers in the history sidebar.

## 3. Clipboard Shortcut

- [x] Register a global keyboard shortcut for generating from clipboard content.
- [x] Read plain text from `NSPasteboard.general`.
- [x] Show generated QR code in the main window.
- [x] Add menu bar command for "Generate from Clipboard".
- [ ] Add user preferences for customizing the shortcut.
- [x] Define behavior when clipboard is empty or contains non-text data.
- [x] Add permissions and sandbox entitlement notes if global shortcut or screen access requires them.

## 4. QR Recognition

- [x] Recognize QR codes from imported image files using Vision or Core Image detectors.
- [x] Add drag-and-drop image support.
- [x] Add paste-image-from-clipboard recognition.
- [ ] Add screen capture or selected-region recognition flow.
- [x] Display decoded content with copy, open URL, and save-to-history actions.
- [x] Support multiple QR codes detected in one image.
- [x] Add clear error states for no code found, unreadable image, and unsupported file format.

## 5. App Structure

- [x] Split UI into views: generator, history, recognition.
- [x] Add services: QR generation, QR recognition, clipboard access, persistence, shortcut handling.
- [x] Add preferences view and app settings storage with a dedicated preferences model.
- [x] Add menu commands for common actions.
- [x] Add keyboard shortcuts for generate, copy image, copy text, save image, delete selected history, and clear input.
- [x] Add keyboard shortcuts for focus input and open history search.
- [x] Add native macOS Settings window.

## 6. Testing and Quality

- [x] Add unit tests for QR generation output validity.
- [x] Add unit tests for history search and duplicate policy.
- [x] Add recognition tests using generated fixture image with one QR code.
- [ ] Add recognition fixture for multiple QR codes.
- [ ] Add UI smoke tests for generator, history search, and recognition flows.
- [ ] Verify dark mode, light mode, keyboard navigation, and VoiceOver labels.
- [ ] Add basic release checklist for signing, notarization, and distribution.

## 8. Open Source Readiness

- [x] Add MIT license.
- [x] Add contributing guide.
- [x] Add code of conduct.
- [x] Add security policy.
- [x] Add changelog.
- [x] Add GitHub Actions CI.
- [x] Add GitHub Actions release workflow for tag-based artifacts.
- [x] Add issue templates and pull request template.
- [x] Add Dependabot configuration for GitHub Actions.
- [x] Add EditorConfig.
- [x] Add support document.
- [x] Add release checklist.
- [x] Add Makefile convenience commands.
- [ ] Replace placeholder repository owner links after creating the GitHub repository.
- [ ] Add code signing and notarization to release workflow.

## 7. First Milestone

- [x] Implement text input to QR preview.
- [x] Add copy image and save PNG.
- [x] Save generated entries into local history.
- [x] Add searchable history list.
- [x] Add clipboard generation through app menu shortcut.
