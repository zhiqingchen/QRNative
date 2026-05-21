#!/usr/bin/env bash
set -euo pipefail

DMG_PATH="${1:-.build/QRNative-macOS.dmg}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ABS_DMG_PATH="$ROOT_DIR/${DMG_PATH#./}"
MOUNT_DIR="$(mktemp -d /tmp/qrnative-dmg.XXXXXX)"

cleanup() {
  hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
  rmdir "$MOUNT_DIR" 2>/dev/null || true
}
trap cleanup EXIT

hdiutil attach "$ABS_DMG_PATH" -mountpoint "$MOUNT_DIR" -nobrowse -readonly -quiet

test -d "$MOUNT_DIR/QRNative.app"
test -e "$MOUNT_DIR/Applications"
test -f "$MOUNT_DIR/QRNative.app/Contents/Info.plist"

echo "Validated $ABS_DMG_PATH"

