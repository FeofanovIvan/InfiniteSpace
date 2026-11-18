#!/bin/bash
# Launch the actual chapter-one Godot game, not an HTML mockup.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd -P)"
cd "$ROOT"
echo "MIKA / InfiniteSpace — Story playtest"
echo "Project: $ROOT"
for required in "project.godot" "scenes/main.tscn" "scripts/Main.gd" "mika_motion_comic/assets/pages/ch01_p01_full.jpg" "mika_motion_comic/assets/pages/ch01_p02_story.jpg"; do
  if [[ ! -f "$ROOT/$required" ]]; then echo "ERROR: missing $required"; exit 1; fi
done
GODOT="${GODOT_BIN:-}"
if [[ -n "$GODOT" && ! -x "$GODOT" ]]; then echo "ERROR: GODOT_BIN not executable: $GODOT"; exit 1; fi
if [[ -z "$GODOT" ]]; then
  for candidate in "/Applications/Godot.app/Contents/MacOS/Godot" "/Applications/Godot 4.7.1.app/Contents/MacOS/Godot" "$HOME/Applications/Godot.app/Contents/MacOS/Godot" "$HOME/Applications/Godot 4.7.1.app/Contents/MacOS/Godot"; do
    if [[ -x "$candidate" ]]; then GODOT="$candidate"; break; fi
  done
fi
if [[ -z "$GODOT" ]]; then
  for candidate in godot godot4 Godot; do
    if command -v "$candidate" >/dev/null 2>&1; then GODOT="$(command -v "$candidate")"; break; fi
  done
fi
if [[ -z "$GODOT" ]]; then
  echo "ERROR: Godot executable not found."
  echo "Open this directory as a Godot 4.7.1 project and press F5, or supply:"
  echo 'GODOT_BIN="/path/to/Godot.app/Contents/MacOS/Godot" bash RUN_STORY.command'
  exit 1
fi
VERSION="$("$GODOT" --version 2>&1 | head -n 1)"
echo "Godot: $VERSION"
if [[ "$VERSION" != 4.7* ]]; then echo "WARNING: This branch targets Godot 4.7.x."; fi
echo "[1/2] Importing assets in this isolated worktree..."
"$GODOT" --headless --editor --path "$ROOT" --import
echo "[2/2] Launching real Godot game — story starts automatically."
echo "Page 1 is timed; tap on the stills of page 2; visit and leave the simulator."
echo "The existing skip arrow returns to Free World."
exec "$GODOT" --path "$ROOT"
