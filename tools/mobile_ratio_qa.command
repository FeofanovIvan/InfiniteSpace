#!/bin/bash
# MIKA ratio QA. Run in macOS Terminal from any working directory.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="/Applications/Godot 4.7.1.app/Contents/MacOS/Godot"
if [ ! -x "$GODOT" ]; then
  echo "Godot 4.7.1.app не найден по пути: $GODOT"
  echo "Откройте проект вручную в установленной версии Godot."
  exit 1
fi
echo 'Выберите пропорции экрана для проверки вступления:'
echo '1) 16:9    1280×720 (YouTube)'
echo '2) 21:9    1260×540 (ultrawide)'
echo '3) 20:9    1200×540 (телефон)'
echo '4) 16:10   1152×720 (ноутбук)'
echo '5) 4:3     960×720 (планшет)'
read -r -p 'Номер [1-5]: ' PICK
case "$PICK" in
  1) DIM='1280x720';;
  2) DIM='1260x540';;
  3) DIM='1200x540';;
  4) DIM='1152x720';;
  5) DIM='960x720';;
  *) echo 'Неверный номер'; exit 1;;
esac
"$GODOT" --path "$ROOT" --resolution "$DIM"
