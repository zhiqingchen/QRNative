#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${1:-debug}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

swift build -c "$CONFIGURATION"

BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
APP_DIR="$ROOT_DIR/.build/QRNative.app"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BIN_DIR/QRNative" "$APP_DIR/Contents/MacOS/QRNative"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
if [[ -f "$ROOT_DIR/Resources/QRNative.icns" ]]; then
  cp "$ROOT_DIR/Resources/QRNative.icns" "$APP_DIR/Contents/Resources/QRNative.icns"
fi

chmod +x "$APP_DIR/Contents/MacOS/QRNative"
touch "$APP_DIR"

# Code sign the whole bundle so its resources are sealed. Without a sealed
# signature, a quarantined download is reported by Gatekeeper as "damaged" and
# refuses to open. Prefer a stable identity (keeps Accessibility/TCC grants
# across rebuilds; override with CODESIGN_IDENTITY for an "Apple Development:"
# or "Developer ID" cert). When that cert is absent (e.g. on CI), fall back to
# an ad-hoc signature, which needs no certificate but still seals the bundle.
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-QRNative Local Codesign}"
if [[ "$CODESIGN_IDENTITY" != "-" ]] && ! security find-certificate -c "$CODESIGN_IDENTITY" >/dev/null 2>&1; then
  echo "Signing identity '$CODESIGN_IDENTITY' not found; falling back to ad-hoc signature." >&2
  CODESIGN_IDENTITY="-"
fi
codesign --force --sign "$CODESIGN_IDENTITY" \
  --identifier "dev.local.QRNative" \
  "$APP_DIR" >&2
echo "Signed with: $CODESIGN_IDENTITY" >&2

echo "$APP_DIR"
