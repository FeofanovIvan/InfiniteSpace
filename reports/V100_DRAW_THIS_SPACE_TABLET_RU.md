# InfiniteSpace v100 — «Нарисуй это» в стиле планшета

Проверены исходники GitHub: игра **уже перенесена** из Safe City Kids в ветку `release/v94-ten-simulator-cards-three-empty-scenes`. Исходная сцена `education/playtown/scenes/features/draw_this/draw_this_game.tscn`, основные файлы `education/playtown/src/features/draw_this/draw_this_game.gd` и `draw_this_canvas.gd`. В `education/playtown_catalog.json` она зарегистрирована как `draw_this` (`sim_05` в новой карусели). Ветка по умолчанию пока старее и не содержит эту импортированную сцену; не путать отсутствие в default с отсутствием в release.

Локальный ZIP-патч: `InfiniteSpace_v100_DrawThis_SpaceTablet_RocketPlanet.zip`, SHA-256 `d8adddaa352921fbb5c351703492d227f82c2e1353a515a902233021a0c98f1b`, размер 107781 байт.

## Состав

* Изменяются **ровно два существующих скрипта** — `draw_this_game.gd`, `draw_this_canvas.gd`. Оригинальная `.tscn` и `Main.gd` не изменяются.
* Бирюзовый ColorRect заменён на `simulator_ui/scripts/real_space_background.gd` (настоящие Starfield + FarPlasma + DistantEvents v91), в том числе при paused parent.
* Панели: тёмно-синий полупрозрачный корпус с cyan neon border, тёмная боковая панель, светло-голубые контуры; кнопки cyan-outline / gold-orange selected, ориентир — наш планшет и Launch.
* **Оригинальная бумага `DrawThisCanvas._draw_paper` остаётся неизменной**: `Color("#fffef9")`, линии сетки, ввод touch/mouse, strokes, стирание и очистка полностью сохраняются.
* New vector-based transparent PNG 512×512 + SVG sources `space/rocket` / `space/planet` добавлены и подставлены в sidebar exercise icon, white-paper exercise and animated preview вместо `butterfly.webp` / `flower.webp`.
* Внутри игры старую кнопку Exit с домиком заменяет единственная голубая неоновая стрелка `planet_hub/scripts/back_arrow_glyph.gd`; верхняя левая внешняя `ReturnToEducationalCards` скрывается только на время Draw It и восстанавливается при выходе. Оболочка `MikoMainMenu.gd` не меняется.
* Кристаллы **не начисляются**: нынешний Draw This не имеет оценки правильности трассы и не следует награждать за произвольные линии. Это отдельная задача дальнейшей разработки.

## Установка на Mac Godot 4.7.1

```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v100_DrawThis_SpaceTablet_RocketPlanet.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v100.sh | bash -s -- "$PROJECT" "$ZIP"
```

Создаёт `InfiniteSpace_backup_before_v100_*` рядом с проектом; имеет rollback script в архиве; не перезаписывает Main.gd и остальные игры. Требует существующих оригинальных скриптов, импортированного каталогa и v91. Не отправляет изменения на ветку GitHub по умолчанию.

**Проверено:** точные маркеры кода в исходниках ветки v94, ZIP integrity + SHA, Python compile, Bash syntax, mocked source-anchor transformation, idempotence, mock installer/backup/reinstall/rollback, guard for local unknown changes. **Не проверено:** реальный запуск GPU Godot 4.7.1 в контейнере; на Mac установщик выполняет headless import и записывает `~/Downloads/InfiniteSpace_v100_Godot_check.log`.

GitHub-ветка содержит отчёт и ссылки на исходники, но не двоичные новые PNG из локального ZIP; ZIP является способом установки на Mac.
