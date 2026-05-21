# AGENTS.md

## Project

QRNative is a native macOS SwiftUI app for generating, storing, searching, and recognizing QR codes.

## Product Requirements

- Generate QR codes from typed text.
- Keep local QR code history and support search.
- Generate a QR code from clipboard text through a keyboard shortcut.
- Recognize QR codes from image files and pasted clipboard images.
- Prefer native Apple frameworks over third-party dependencies.

## Tech Stack

- Swift 6
- SwiftUI for the macOS UI
- AppKit for pasteboard, image export, open/save panels, and global hotkey support
- Core Image for QR code generation
- Vision for QR code recognition
- JSON file persistence for local history
- Swift Testing for unit tests

## Commands

```bash
swift build
swift test
swift run QRNative
```

## Code Organization

- `Sources/QRNativeCore`: reusable models and services.
- `Sources/QRNative`: macOS app entry point and SwiftUI views.
- `Tests/QRNativeCoreTests`: unit tests for core behavior.
- `docs/TODO.md`: implementation checklist and milestone tracking.

## Implementation Notes

- Keep code focused and native. Do not add external packages unless a requirement cannot be met with Apple frameworks.
- Keep UI state in observable view models and keep QR generation, recognition, clipboard, persistence, and shortcut handling in services.
- Persist history in the user's Application Support directory by default.
- Make image output crisp by rendering QR images without interpolation.
- Treat global shortcut registration as a best-effort native feature. If registration fails, keep the app menu shortcut working.

## Verification

Before handing work back, run:

```bash
swift test
swift build
```

If either command cannot run, document the reason in the final response.

