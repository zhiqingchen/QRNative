# Contributing

Thanks for helping make QRNative better.

## Development Setup

Requirements:

- macOS 14 or newer
- Xcode command line tools
- Swift 6

Useful commands:

```bash
swift build
swift test
swift run QRNative
./scripts/build-app.sh
```

Convenience commands:

```bash
make test
make app
make release
```

## Workflow

1. Open an issue for larger behavior changes.
2. Keep PRs focused and small enough to review comfortably.
3. Add or update tests for QR generation, recognition, history, or persistence changes.
4. Run `swift test` before opening a PR.
5. Update `README.md`, `docs/TODO.md`, or `docs/ARCHITECTURE.md` when behavior changes.

## Design Principles

- Prefer native Apple frameworks.
- Keep the app private by default; QR payloads should stay local.
- Keep the UI fast, keyboard-friendly, and useful without setup.
- Avoid external dependencies unless they remove real complexity.

## Commit Style

Use short imperative commit messages, for example:

```text
Add clipboard QR generation
Improve history search
```
