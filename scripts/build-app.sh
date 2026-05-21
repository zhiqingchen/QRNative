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

echo "$APP_DIR"
