#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/.build/QRNative.app"
DMG_DIR="$ROOT_DIR/.build/dmg"
DMG_PATH="$ROOT_DIR/.build/QRNative-macOS.dmg"
VOLUME_NAME="QRNative"

if [[ ! -d "$APP_DIR" ]]; then
  "$ROOT_DIR/scripts/build-app.sh" release >/dev/null
fi

rm -rf "$DMG_DIR" "$DMG_PATH"
mkdir -p "$DMG_DIR"

cp -R "$APP_DIR" "$DMG_DIR/QRNative.app"
ln -s /Applications "$DMG_DIR/Applications"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

rm -rf "$DMG_DIR"

echo "$DMG_PATH"

