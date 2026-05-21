# Release Checklist

QRNative currently ships unsigned release artifacts from GitHub Actions. Signing and notarization are tracked as future work.

## Before Release

- [ ] Update `CHANGELOG.md`.
- [ ] Confirm `README.md` reflects current features.
- [ ] Run `swift test`.
- [ ] Run `./scripts/build-app.sh release`.
- [ ] Smoke test `.build/QRNative.app`.
- [ ] Confirm `Resources/QRNative.icns` appears in the app bundle.

## Create Release

Create and push a tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

The Release workflow will:

- Run tests.
- Regenerate brand assets.
- Build the release app bundle.
- Package `.build/QRNative.app` as `.build/QRNative-macOS.zip`.
- Generate a SHA-256 checksum.
- Attach both files to the GitHub Release.

## Future Signing and Notarization

Planned production release work:

- Add Developer ID certificate import from GitHub Actions secrets.
- Codesign the app with hardened runtime.
- Notarize with Apple notary service.
- Staple the notarization ticket.
- Consider publishing a Homebrew cask.

