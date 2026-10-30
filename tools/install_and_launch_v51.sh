#!/bin/bash
# v51: install, run static checks, sync full PNG snapshot, open Godot.
set -euo pipefail
PROJECT="${1:-$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot}"
ZIP="$2"
unzip -tq "$ZIP"
TMP_INSTALLER="$(mktemp "${TMPDIR:-/tmp/}install_v51.XXXXXX")"
trap 'rm -f "$TMP_INSTALLER"' EXIT
unzip -p "$ZIP" install_v51.py > "$TMP_INSTALLER"
test -s "$TMP_INSTALLER"
python3 -m py_compile "$TMP_INSTALLER"
python3 "$TMP_INSTALLER" "$PROJECT" "$ZIP"
if unzip -p "$ZIP" sync_v51_to_github.sh | bash -s -- "$PROJECT"; then
  echo 'GitHub synchronized.'
else
  echo 'WARNING: GitHub was not synchronized; local v51 installation is intact.' >&2
fi
APP='/Applications/Godot 4.7.1.app'
if [ -d "$APP" ]; then
  open -n -a "$APP" --args --editor --path "$PROJECT"
else
  echo 'WARNING: Godot 4.7.1.app was not found at /Applications. Launch manually.' >&2
  exit 1
fi
echo 'Godot editor launch requested after successful v51 installation.'
