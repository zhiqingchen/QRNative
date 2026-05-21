<p align="center">
  <img src="Assets/Brand/qrnative-logo.png" width="128" alt="QRNative logo">
</p>

<h1 align="center">QRNative</h1>

<p align="center">
  Native macOS QR code generator, history manager, and recognizer.
</p>

<p align="center">
  <img alt="CI" src="https://img.shields.io/badge/CI-GitHub%20Actions-2088ff">
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS-lightgrey">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-6-orange">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-blue"></a>
</p>

QRNative is a privacy-friendly native macOS app for generating QR codes from text or clipboard content, keeping searchable local history, exporting crisp PNGs, and recognizing QR codes from images.

## Features

- Generate QR codes from typed text.
- Keep searchable local QR code history.
- Generate QR codes from clipboard text with `Shift + Command + V`.
- Use a configurable global clipboard shortcut when macOS allows registration; the default is `Control + Option + Command + Q`.
- Show a floating QR code for selected text from any app; the default shortcut is `Option + T`.
- Capture a screen region, recognize QR content, and copy the decoded text; the default shortcut is `Option + R`.
- Use macOS Services from selected text or selected image content in other apps.
- Recognize QR codes from image files, dragged images, or clipboard images.
- Copy QR images, copy decoded text, open decoded URLs, and export PNG files.
- Configure defaults from the native macOS Settings window.
- Keep payloads local; no network access is needed for normal use.

## Requirements

- macOS 14 or newer
- Xcode command line tools
- Swift 6

## Development

```bash
swift build
swift test
swift run QRNative
```

Or use the convenience Makefile:

```bash
make test
make app
make release
```

## Build a `.app` Bundle

```bash
./scripts/build-app.sh
open .build/QRNative.app
```

The app bundle includes the generated `Resources/QRNative.icns` icon.

## Build a DMG Installer

```bash
./scripts/build-app.sh release
./scripts/build-dmg.sh
open .build/QRNative-macOS.dmg
```

The DMG contains `QRNative.app` and an `/Applications` shortcut for drag-and-drop installation.

## CI/CD

- CI: `.github/workflows/ci.yml` runs build, tests, and app bundle creation for pushes and pull requests.
- Release: `.github/workflows/release.yml` runs on `v*` tags, packages `.build/QRNative.app` as DMG and zip artifacts, generates SHA-256 checksums, and publishes them to GitHub Releases.
- Release checklist: `docs/RELEASE.md`

## Settings

Open `QRNative > Settings...` to configure:

- Default QR correction level.
- Live preview while typing.
- Whether typed, clipboard, and recognized QR codes are saved to history.
- Global clipboard shortcut behavior.
- Local history file management.

## macOS Services

QRNative registers two Services in the app bundle:

- `QRNative: Generate QR from Selected Text`: use on selected text.
- `QRNative: Recognize QR in Selected Image`: use on selected images or image files.

After installing and launching the app, use them from another app's context menu:

```text
Right click selected text or image > Services > QRNative: ...
```

To add a keyboard shortcut:

```text
System Settings > Keyboard > Keyboard Shortcuts > Services
```

QRNative also includes a `Settings > Selection` page with these steps and an open button.

The Services route is the macOS-native way to receive the current selection from other apps. QRNative also includes a configurable selected-text global shortcut that temporarily copies the current selection, restores the previous clipboard, and shows a floating QR code. macOS may ask for Accessibility permission before this shortcut can copy text from the frontmost app.

## Brand Assets

- Logo source: `Assets/Brand/qrnative-logo.svg`
- README logo: `Assets/Brand/qrnative-logo.png`
- App icon: `Resources/QRNative.icns`
- Brand guide: `docs/BRANDING.md`

Regenerate derived brand assets:

```bash
./scripts/generate-brand-assets.swift
```

## Local Data

History is stored as JSON in:

```text
~/Library/Application Support/QRNative/history.json
```

## Project Layout

- `Sources/QRNativeCore`: models and services for generation, recognition, clipboard, and history.
- `Sources/QRNative`: SwiftUI macOS application.
- `Tests/QRNativeCoreTests`: unit tests for core behavior.
- `docs`: task list, architecture notes, and branding notes.
- `.github`: CI workflow and contribution templates.
- `Makefile`: local shortcuts for common development and release commands.

## Contributing

Contributions are welcome. See `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, and `SECURITY.md`.

Before opening a pull request, run:

```bash
swift test
swift build
./scripts/build-app.sh
```

## License

QRNative is released under the MIT License. See `LICENSE`.
