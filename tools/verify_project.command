#!/bin/bash
set -u
PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
APP="/Applications/Godot 4.7.1.app"
STAMP="$(date +%Y%m%d_%H%M%S)"
mkdir -p "$PROJECT/reports"
LOG="$PROJECT/reports/Godot_Preflight_${STAMP}.log"
BIN=""
if [ -d "$APP/Contents/MacOS" ]; then
  for CANDIDATE in "$APP"/Contents/MacOS/*; do
    if [ -f "$CANDIDATE" ] && [ -x "$CANDIDATE" ]; then
      BIN="$CANDIDATE"
      break
    fi
  done
fi
if [ -z "$BIN" ]; then
  echo "Godot executable не найден: $APP"
  echo "Установку можно проверить вручную в редакторе Godot (F5)."
  exit 2
fi
printf 'Checking with %s\n' "$BIN"
"$BIN" --headless --path "$PROJECT" --editor --quit > "$LOG" 2>&1
STATUS=$?
cat "$LOG"
if [ "$STATUS" -ne 0 ] || grep -Eq 'SCRIPT ERROR:|Parse Error:|Parser Error:' "$LOG"; then
  echo "ПРОВЕРКА НЕ ПРОЙДЕНА. Пришли файл: $LOG"
  exit 1
fi
echo "Готово: ошибок разбора GDScript в журнале не обнаружено."
echo "Проверка визуального отображения шейдера требует обычного запуска F5."
echo "Журнал: $LOG"
