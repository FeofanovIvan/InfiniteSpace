# InfiniteSpace v78 — Баббл +15%, кристаллы симулятора как в PlanetHub

**ZIP:** `InfiniteSpace_v78_Bubble15_PlanetHubCrystalCounter.zip`, 8565 байт, SHA256 `96c2f32c995306f339d55220549e288cd89561c6d06c8b1b9d9e338ed55d3b33`.

## Исправления
- `scripts/MikoMainMenu.gd`: анимированная сцена Bubble v77 увеличена на **15%** (`bubble_scale = 0.32 * ui_scale` → `0.368 * ui_scale`). Радиус безопасных границ и область нажатия уже вычисляются от `bubble_scale`, поэтому растут вместе с ним.
- Счётчик в симуляторе: **полная композиция** центрального счётчика `planet_hub/scripts/bottom_hud.gd` из v68: ресурсы `crystals_panel.png` и `crystal_reference.png`, двойной голубой разделитель `CounterDividerGlow` / `CounterDivider`, координаты оригинального 394×158 элемента, уменьшенные с коэффициентом `(68 / 158) * scale`.
- **Высота панели кристаллов = высота кнопки «Назад» = `68 * scale`**, оба верхним краем на `20 * scale`, панель прикреплена к правому краю с отступом `24 * scale`; кнопка слева с тем же отступом. Число остаётся живым и автоматически подгоняет размер шрифта при изменении баланса.
- Другие файлы не затрагиваются. Используются существующие ассеты PlanetHub, без новых графических генераций, без переписывания `Main.gd`, Баббла, мини-игр и нижней панели.

## Установка
```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v78_Bubble15_PlanetHubCrystalCounter.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v78.sh | bash -s -- "$PROJECT" "$ZIP"
```

Установщик требует структурно распознаваемый исходник v77, проверяет CRC архива и SHA патчера, выполняет preflight, копирует `scripts/MikoMainMenu.gd` в резервную папку рядом с проектом, атомарно устанавливает изменение с rollback и поддерживает повторную установку. Затем выполняет импорт в Godot и открывает редактор и игру на Mac. Лог: `~/Downloads/InfiniteSpace_v78_Godot_check.log`.

**Тесты:** Python compile PASS, bash syntax PASS, структурный патч + повтор PASS, проверка 15% PASS, пропорции v68 + два разделителя PASS, живой баланс PASS, ZIP CRC и manifest SHA PASS, end-to-end установка и backup PASS, неизвестный локальный скрипт отвергается PASS. **Godot GUI/F5 на Mac из сборочной среды не запускается** — визуально проверяется после установки.

Эта ветка — паспорт патча, **не полный снимок локальной сборки**. Истинная установленная версия пользователя на Mac не заменяется репозиторием.
