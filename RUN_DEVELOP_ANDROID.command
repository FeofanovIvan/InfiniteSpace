#!/bin/bash
# MIKA InfiniteSpace: local Godot 4.7.1 development build for Android.
# This is intentionally isolated from the existing production installation.
set -euo pipefail

MIKA_DEV_DIR="$(cd "$(dirname "$0")" && pwd -P)"
MIKA_GODOT_BIN="${GODOT_BIN:-/Applications/Godot 4.7.1.app/Contents/MacOS/Godot}"
MIKA_EXPORT_PRESET="Android Debug (ARM64)"
MIKA_PACKAGE_ID="com.feofanov.infinitespace.dev"
MIKA_ACTION="${1:---apk}"

if [[ ! -x "$MIKA_GODOT_BIN" ]]; then
  echo "ERROR: Godot 4.7.1 not found: $MIKA_GODOT_BIN" >&2
  echo "Set GODOT_BIN to your Godot executable and retry." >&2
  exit 2
fi
if [[ ! -f "$MIKA_DEV_DIR/project.godot" || ! -f "$MIKA_DEV_DIR/export_presets.cfg" ]]; then
  echo "ERROR: open this script from the checked-out InfiniteSpace develop worktree." >&2
  exit 2
fi
if ! grep -Fq "package/unique_name=\"$MIKA_PACKAGE_ID\"" "$MIKA_DEV_DIR/export_presets.cfg"; then
  echo "ERROR: Android debug package ID differs from $MIKA_PACKAGE_ID." >&2
  echo "Refusing to build a potentially production-overwriting APK." >&2
  exit 2
fi
if ! grep -Fq "name=\"$MIKA_EXPORT_PRESET\"" "$MIKA_DEV_DIR/export_presets.cfg"; then
  echo "ERROR: Android debug export preset is missing." >&2
  exit 2
fi

echo "Project: $MIKA_DEV_DIR"
echo "Branch: $(git -C "$MIKA_DEV_DIR" branch --show-current 2>/dev/null || true)"
echo "Godot: $("$MIKA_GODOT_BIN" --version)"
echo "Device package: $MIKA_PACKAGE_ID (separate from production)"

case "$MIKA_ACTION" in
  --editor)
    exec "$MIKA_GODOT_BIN" --editor --path "$MIKA_DEV_DIR"
    ;;
  --game)
    exec "$MIKA_GODOT_BIN" --path "$MIKA_DEV_DIR"
    ;;
  --apk|--install)
    ;;
  *)
    echo "Usage: bash RUN_DEVELOP_ANDROID.command [--editor|--game|--apk|--install]" >&2
    exit 2
    ;;
esac

MIKA_OUTPUT_DIR="${MIKA_ANDROID_OUTPUT_DIR:-$HOME/Downloads}"
mkdir -p "$MIKA_OUTPUT_DIR"
MIKA_BUILD_STAMP="$(date '+%Y%m%d_%H%M%S')"
MIKA_OUTPUT_APK="$MIKA_OUTPUT_DIR/MIKA_develop_0.36.0_debug_${MIKA_BUILD_STAMP}.apk"

echo "[1/2] Importing resources for this isolated development worktree..."
"$MIKA_GODOT_BIN" --headless --editor --path "$MIKA_DEV_DIR" --import
echo "[2/2] Exporting Android Debug (ARM64)..."
"$MIKA_GODOT_BIN" --headless --path "$MIKA_DEV_DIR" --export-debug "$MIKA_EXPORT_PRESET" "$MIKA_OUTPUT_APK"

if [[ ! -s "$MIKA_OUTPUT_APK" ]]; then
  echo "ERROR: Godot did not create a non-empty APK." >&2
  exit 1
fi
echo "APK READY: $MIKA_OUTPUT_APK"
ls -lh "$MIKA_OUTPUT_APK"
shasum -a 256 "$MIKA_OUTPUT_APK"

if [[ "$MIKA_ACTION" != --install ]]; then
  echo "To install on Android using USB debugging, run:"
  echo "  bash \"$MIKA_DEV_DIR/RUN_DEVELOP_ANDROID.command\" --install"
  echo "Or copy this APK to your Android phone and install it manually."
  exit 0
fi

MIKA_ADB_BIN="$(command -v adb || true)"
if [[ -z "$MIKA_ADB_BIN" && -x "$HOME/Library/Android/sdk/platform-tools/adb" ]]; then
  MIKA_ADB_BIN="$HOME/Library/Android/sdk/platform-tools/adb"
fi
if [[ -z "$MIKA_ADB_BIN" ]]; then
  echo "ADB not installed. APK is ready at: $MIKA_OUTPUT_APK" >&2
  exit 0
fi
echo "Connected Android devices:"
"$MIKA_ADB_BIN" devices -l
read -r -p "Install this .dev APK onto your connected Android device? [y/N] " MIKA_CONFIRM
if [[ "$MIKA_CONFIRM" != y && "$MIKA_CONFIRM" != Y ]]; then
  echo "Installation cancelled. APK remains at: $MIKA_OUTPUT_APK"
  exit 0
fi
"$MIKA_ADB_BIN" install -r "$MIKA_OUTPUT_APK"
echo "INSTALLED: $MIKA_PACKAGE_ID"
echo "Launching the installed development game..."
"$MIKA_ADB_BIN" shell monkey -p "$MIKA_PACKAGE_ID" -c android.intent.category.LAUNCHER 1
