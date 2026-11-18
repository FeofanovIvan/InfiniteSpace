#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
GODOT_BIN="/Applications/Godot 4.7.1.app/Contents/MacOS/Godot"

if [ ! -x "$GODOT_BIN" ]; then
	echo "Godot 4.7.1 not found at: $GODOT_BIN" >&2
	exit 2
fi

exec "$GODOT_BIN" --path "$PROJECT_DIR"
