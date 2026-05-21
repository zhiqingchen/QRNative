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

# Code sign with a stable identity so macOS keeps Accessibility (and other TCC)
# grants across rebuilds. Defaults to the local self-signed cert; override with
# CODESIGN_IDENTITY (e.g. an "Apple Development: ..." identity) if you prefer.
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-QRNative Local Codesign}"
if security find-certificate -c "$CODESIGN_IDENTITY" >/dev/null 2>&1 || [[ "$CODESIGN_IDENTITY" == "-" ]]; then
  codesign --force --sign "$CODESIGN_IDENTITY" \
    --identifier "dev.local.QRNative" \
    "$APP_DIR" >&2
  echo "Signed with: $CODESIGN_IDENTITY" >&2
else
  echo "WARNING: signing identity '$CODESIGN_IDENTITY' not found; app left unsigned." >&2
fi

echo "$APP_DIR"
