#!/usr/bin/env bash
# One safe convention for future InfiniteSpace patches: install, validate, then open Godot.
set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "Usage: bash tools/install_and_open_godot_macos.sh PATCH.zip install_vNN.py [PROJECT_DIRECTORY]" >&2
  exit 2
fi

ZIP="$1"
INSTALLER="$2"
PROJECT="${3:-$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot}"
GODOT_APP="/Applications/Godot 4.7.1.app"

if [ ! -f "$ZIP" ] || [ ! -f "$PROJECT/project.godot" ]; then
  echo "Missing ZIP or Godot project. No launch performed." >&2
  exit 1
fi

unzip -tq "$ZIP"
TEMP_INSTALLER="$(mktemp "${TMPDIR:-/tmp/}infinite_install.XXXXXX")"
trap 'rm -f "$TEMP_INSTALLER"' EXIT
unzip -p "$ZIP" "$INSTALLER" > "$TEMP_INSTALLER"
test -s "$TEMP_INSTALLER"
python3 -m py_compile "$TEMP_INSTALLER"
python3 "$TEMP_INSTALLER" "$PROJECT" "$ZIP"

# Only reached on installer success. open returns launch-request status,
# not proof that the Godot project subsequently parsed or ran without errors.
if [ -d "$GODOT_APP" ]; then
  open -n -a "$GODOT_APP" --args --editor --path "$PROJECT"
elif command -v godot >/dev/null 2>&1; then
  godot --editor --path "$PROJECT" &
else
  echo "Patch installed, but Godot 4.7.1.app wasn't found at $GODOT_APP" >&2
  exit 1
fi
echo "Install succeeded; Godot editor launch requested: $PROJECT"
