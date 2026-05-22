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

# Guard against single-arch regressions: the shipped binary must be universal.
BINARY="$MOUNT_DIR/QRNative.app/Contents/MacOS/QRNative"
test -f "$BINARY"
ARCHS="$(lipo -archs "$BINARY")"
for arch in arm64 x86_64; do
  case " $ARCHS " in
    *" $arch "*) ;;
    *) echo "Missing $arch slice in $BINARY (got: $ARCHS)" >&2; exit 1 ;;
  esac
done

echo "Validated $ABS_DMG_PATH"

