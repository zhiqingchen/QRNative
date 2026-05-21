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
- `GlobalHotKeyManager`: registers `Control + Option + Command + Q` as a best-effort global shortcut.

## UI

The app uses a split layout:

- Sidebar: searchable history.
- Generate tab: text editor, correction level picker, QR preview, copy/export actions.
- Recognize tab: image import, paste, drag-and-drop, decoded payload actions.
- Menus: generation, clipboard, recognition, copy, save, delete, and clear commands are exposed for keyboard-driven use.
- Preview generation is debounced while typing and does not write history until the user explicitly saves/generates.

## Data Policy

History stays local on disk. The app does not use network access and does not send payloads anywhere.

## Packaging

`scripts/build-app.sh` builds the SwiftPM executable into `.build/QRNative.app`, copies `Resources/Info.plist`, and includes `Resources/QRNative.icns` when present.

`scripts/generate-brand-assets.swift` regenerates the README PNG logo and macOS `.icns` app icon from native drawing code. The source logo remains editable in `Assets/Brand/qrnative-logo.svg`.

## CI/CD

- CI workflow: build, test, and app bundle smoke packaging on push and pull request.
- Release workflow: on `v*` tags or manual dispatch, test, build release, zip `.app`, generate checksum, and publish GitHub Release artifacts.
- Signing and notarization are intentionally left as future work until Apple Developer credentials are available in repository secrets.
