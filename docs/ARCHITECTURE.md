# QRNative Architecture

## Overview

QRNative is split into a testable core target and a macOS app target.

## Targets

- `QRNativeCore`: pure product behavior backed by Apple frameworks.
- `QRNative`: SwiftUI views, menu commands, save/open panels, and global hotkey registration.
- `QRNativeCoreTests`: generation, recognition, history search, and duplicate-policy tests.
- `Assets/Brand`: editable logo source and derived README logo.
- `.github`: CI, Dependabot, release, issue, and pull request metadata.

## Services

- `QRCodeGenerator`: uses Core Image `CIQRCodeGenerator` and exports crisp `NSImage`, `CGImage`, and PNG data.
- `QRRecognizer`: uses Vision barcode detection with QR symbology.
- `QRHistoryStore`: stores history as JSON under Application Support.
- `ClipboardService`: reads text/images and writes text/images through `NSPasteboard`.
- `GlobalHotKeyManager`: registers user-configurable clipboard, selected-text, and screenshot-recognition shortcuts as best-effort global shortcuts.
- `SelectedTextService`: reads selected text from the frontmost app by issuing a copy command, then restores the previous pasteboard contents.
- `ScreenshotCaptureService`: invokes the system interactive screenshot tool and returns captured PNG data for Vision recognition.

## UI

The app uses a split layout:

- Sidebar: searchable history.
- Generate tab: text editor, correction level picker, QR preview, copy/export actions.
- Recognize tab: image import, paste, drag-and-drop, decoded payload actions.
- Menus: generation, clipboard, recognition, copy, save, delete, and clear commands are exposed for keyboard-driven use.
- Preview generation is debounced while typing and does not write history until the user explicitly saves/generates.
- Settings scene: native macOS Settings window for defaults, shortcuts, local data, and about information.
- Services: app bundle declares macOS Services for selected text and selected image input; service handlers show a floating result panel near the pointer.

## Data Policy

History stays local on disk. The app does not use network access and does not send payloads anywhere.

## Settings

`AppSettings` stores user preferences in `UserDefaults` and is injected alongside `AppState`.

Settings currently control:

- Default QR correction level.
- Automatic preview refresh.
- History saving policy for typed, clipboard, and recognized payloads.
- Whether the global clipboard shortcut is registered.
- Whether the selected-text shortcut is registered.
- Whether the screenshot recognition shortcut is registered.
- Whether clipboard generation brings QRNative to the front.
- Whether QR codes generated through Services are saved to history.

## Services

`Resources/Info.plist` declares `NSServices` entries:

- `QRNative: Generate QR from Selected Text` accepts selected text and calls `generateQRCodeFromSelection:userData:error:`.
- `QRNative: Recognize QR in Selected Image` accepts selected image/file input and calls `recognizeQRCodeFromSelection:userData:error:`.

`QRNativeServicesProvider` is installed as `NSApp.servicesProvider` during app startup. Service results are presented with `FloatingResultPresenter`, which positions an `NSPanel` close to the current pointer while also updating the main app state.

The selected-text global shortcut reuses the same floating QR presentation path. Because macOS does not expose arbitrary selected text to background apps, this path uses a temporary copy operation and may require Accessibility permission.

The screenshot recognition shortcut opens the system region capture UI, sends the resulting image through `QRRecognizer`, presents decoded content with `FloatingResultPresenter`, and copies the first decoded payload to the pasteboard.

## Packaging

`scripts/build-app.sh` builds the SwiftPM executable into `.build/QRNative.app`, copies `Resources/Info.plist`, and includes `Resources/QRNative.icns` when present.

`scripts/build-dmg.sh` packages `.build/QRNative.app` into `.build/QRNative-macOS.dmg` with an `/Applications` shortcut for drag-and-drop installation.

`scripts/generate-brand-assets.swift` regenerates the README PNG logo and macOS `.icns` app icon from native drawing code. The source logo remains editable in `Assets/Brand/qrnative-logo.svg`.

## CI/CD

- CI workflow: build, test, and app bundle smoke packaging on push and pull request.
- Release workflow: on `v*` tags or manual dispatch, test, build release, package zip and DMG artifacts, generate checksums, and publish GitHub Release artifacts.
- Signing and notarization are intentionally left as future work until Apple Developer credentials are available in repository secrets.
