#!/bin/bash
# Collect Infinite Space flight logs + Godot engine logs into one ZIP file.
# macOS double-click / bash tools/collect_reports.command
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORTS="$PROJECT/reports"
PROJECT_TITLE="Infinite Space - Distant Stars"
DATE_STAMP="$(date +%Y%m%d_%H%M%S)"
DEST="$REPORTS/InfiniteSpace_Report_${DATE_STAMP}.zip"
STAGING="$(mktemp -d "${TMPDIR:-/tmp}/infinite_space_reports.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
mkdir -p "$REPORTS" "$STAGING/project_information"
{
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "Project path: $PROJECT"
  echo "System: $(uname -srm)"
  echo "Godot project title: $PROJECT_TITLE"
} > "$STAGING/project_information/environment.txt"
cp "$PROJECT/project.godot" "$STAGING/project_information/project.godot"

FOUND=0
for BASE in \
  "$HOME/Library/Application Support/Godot/app_userdata" \
  "$HOME/.local/share/godot/app_userdata" \
  "$HOME/.local/share/Godot/app_userdata"; do
  USER_FOLDER="$BASE/$PROJECT_TITLE"
  if [ -d "$USER_FOLDER/reports" ]; then
    mkdir -p "$STAGING/user_data"
    cp -R "$USER_FOLDER/reports" "$STAGING/user_data/"
    FOUND=1
  fi
  if [ -d "$USER_FOLDER/logs" ]; then
    mkdir -p "$STAGING/godot_engine"
    cp -R "$USER_FOLDER/logs" "$STAGING/godot_engine/"
    FOUND=1
  fi
done

if [ "$FOUND" -eq 0 ]; then
  echo "Godot user data logs were not found in standard folders." > "$STAGING/project_information/no_logs.txt"
  echo "Hint: Godot > Project > Open User Data Folder; copy reports and logs." >> "$STAGING/project_information/no_logs.txt"
fi
(cd "$STAGING" && zip -qr "$DEST" .)
echo ""
echo "DIAGNOSTIC ARCHIVE CREATED:"
echo "$DEST"
echo ""
echo "Send this ZIP in the ChatGPT conversation."
if [ "${TERM:-}" = "dumb" ]; then exit 0; fi
