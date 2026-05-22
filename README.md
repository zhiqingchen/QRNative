<p align="center">
  <img src="Assets/Brand/qrnative-logo.png" width="128" alt="QRNative logo">
</p>

<h1 align="center">QRNative</h1>

<p align="center">
  A native macOS QR utility for generating, recognizing, and keeping local QR history.
</p>

<p align="center">
  <img alt="CI" src="https://img.shields.io/badge/CI-GitHub%20Actions-2088ff">
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS-lightgrey">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-6-orange">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-blue"></a>
</p>

QRNative turns text, clipboard content, selected text, screenshots, and image files into a fast local QR workflow. It is built with SwiftUI, AppKit, Core Image, Vision, and JSON persistence; normal use does not require network access.

## Core Functions

- Generate QR codes from typed text or clipboard text, with live preview and L/M/Q/H correction levels.
- Copy QR images, copy payload text, open URL payloads, and export crisp PNG files.
- Keep searchable local history, load previous entries, copy them, or delete them.
- Recognize QR codes from image files, dragged images, clipboard images, selected images, and screen regions.
- Handle multiple recognized QR codes in one image, then copy, open, or regenerate from the decoded payload.
- Use app shortcuts, configurable global shortcuts, and macOS Services for selected text and selected image workflows.

## Download

Grab the latest `QRNative-macOS.dmg` (or `.zip`) from the [Releases](https://github.com/zhiqingchen/QRNative/releases) page, open the DMG, and drag `QRNative.app` into `/Applications`.

The release build is ad-hoc signed but not notarized (no paid Apple Developer account), so the first launch is gated by Gatekeeper. This is a one-time step:

- **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to QRNative, or
- run once in Terminal:

  ```bash
  xattr -dr com.apple.quarantine /Applications/QRNative.app
  ```

If macOS reports the app as "damaged", you are on an older build that predates the sealed-signature fix — re-download the latest release.

## Requirements

- macOS 13 (Ventura) or newer — universal binary (Apple Silicon & Intel)
- Xcode command line tools
- Swift 6

## Run Locally

```bash
swift build
swift test
swift run QRNative
```

Convenience targets are also available:

```bash
make test
make app
make release
```

## Shortcuts

| Action | Default |
| --- | --- |
| Generate typed content | `Command + Return` |
| Generate from clipboard | `Shift + Command + V` |
| Recognize clipboard image | `Shift + Command + R` |
| Global clipboard QR | `Control + Option + Command + Q` |
| Selected text floating QR | `Option + T` |
| Screenshot QR recognition | `Option + R` |
| Copy QR image | `Option + Command + C` |
| Copy QR text | `Shift + Command + C` |
| Save PNG | `Command + S` |
| Delete selected history item | `Delete` |
| Clear input | `Command + K` |
| Focus input | `Command + L` |
| Search history | `Command + F` |

Global shortcut registration is best effort. If macOS blocks clipboard registration, the app menu shortcut still works. Selected text can also use the macOS Service flow.

## macOS Services

QRNative includes two Services in the app bundle:

- `QRNative: Generate QR from Selected Text`
- `QRNative: Recognize QR in Selected Image`

After installing and launching the app, enable them in:

```text
System Settings > Keyboard > Keyboard Shortcuts > Services
```

The `QRNative > Settings... > Selection` pane includes the same setup path and a button to open the relevant System Settings page.

## Settings And Data

Use `QRNative > Settings...` to configure default correction level, live preview, history saving policy, shortcut behavior, Services history, and local data management.

History is stored as JSON at:

```text
~/Library/Application Support/QRNative/history.json
```

## App Bundle And DMG

```bash
./scripts/build-app.sh
open .build/QRNative.app
```

```bash
./scripts/build-app.sh release
./scripts/build-dmg.sh
open .build/QRNative-macOS.dmg
```

The app bundle includes `Resources/QRNative.icns`. The DMG contains `QRNative.app` and an `/Applications` shortcut for drag-and-drop installation.

## Project Layout

- `Sources/QRNativeCore`: QR generation, recognition, clipboard, models, and history services.
- `Sources/QRNative`: SwiftUI app, AppKit integration, settings, shortcuts, and Services.
- `Tests/QRNativeCoreTests`: Swift Testing coverage for core behavior.
- `Assets/Brand`: logo source and README image.
- `Resources`: app metadata and icon.
- `docs`: architecture, release, branding, and TODO notes.

## Brand Assets

- Logo source: `Assets/Brand/qrnative-logo-source.png`
- README logo: `Assets/Brand/qrnative-logo.png`
- App icon: `Resources/QRNative.icns`
- Brand guide: `docs/BRANDING.md`

Regenerate derived brand assets with:

```bash
./scripts/generate-brand-assets.swift
```

## Contributing

Contributions are welcome. Before opening a pull request, run:

```bash
swift test
swift build
./scripts/build-app.sh
```

See `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, and `docs/RELEASE.md` for project process notes.

## License

QRNative is released under the MIT License. See `LICENSE`.
