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
- Use the global shortcut `Control + Option + Command + Q` when macOS allows registration.
- Recognize QR codes from image files, dragged images, or clipboard images.
- Copy QR images, copy decoded text, open decoded URLs, and export PNG files.
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

## CI/CD

- CI: `.github/workflows/ci.yml` runs build, tests, and app bundle creation for pushes and pull requests.
- Release: `.github/workflows/release.yml` runs on `v*` tags, packages `.build/QRNative.app` as a zip, generates a SHA-256 checksum, and publishes both to GitHub Releases.
- Release checklist: `docs/RELEASE.md`

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
