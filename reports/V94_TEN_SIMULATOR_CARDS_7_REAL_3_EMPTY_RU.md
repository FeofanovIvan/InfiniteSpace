# InfiniteSpace v94 — 10 карточек учебного симулятора

ZIP: `InfiniteSpace_v94_TenSimulatorCards_ThreePlaceholders.zip`, SHA256 `d4fcd387cb216bf555c38d4e687ef469d3a390f8a5f5a28fb2a01811532eabfa`, около 3.4 МБ.

Пользователь утвердил `sim_01`–`sim_10`, семь первых существуют в перенесённом Safe City Kids, три последних — новые, нужна немедленная визуализация всех карточек и отдельные пустые сцены с рабочим переходом/возвратом.

## Сопоставления
1. `sim_01` «Обведи буквы» → legacy `letter_trace` → `letter_trace_game.tscn`.
2. `sim_02` «Обведи слова» → `word_trace` → `word_trace_game.tscn`.
3. `sim_03` «Собери слово» → `word_build` → `school_game.tscn`.
4. `sim_04` «Собери фигуру» → `shape_build` → `shape_build_game.tscn`.
5. `sim_05` «Нарисуй это» → `draw_this` → `draw_this_game.tscn`.
6. `sim_06` «Выбери число» → `pick_number` → `count_pick_game.tscn`.
7. `sim_07` «Напиши число» → `count_groceries` → `count_trace_game.tscn`.
8. `sim_08` «Действия» → новая `simulator_ui/scenes/sim_08_actioncards.tscn` (заготовка).
9. `sim_09` «Где это?» → новая `simulator_ui/scenes/sim_09_whereisit.tscn` (заготовка).
10. `sim_10` «Сортировка по цветам» → новая `simulator_ui/scenes/sim_10_colorsort.tscn` (заготовка).

Десять оригинальных PNG пользователя из `mika_simulator_icons_10_png (1).zip`, все 640×640 RGBA с прозрачностью, перенесены **побайтово**. Иконки вписаны `contain` без обрезки на полупрозрачную светло-голубую область в карточке, основанной на исходной рамке PlanetHub `simulator_game_card.gd`.

**Два примечания:** `sim_09_reward_star.png` изображает звезду/награду, хотя карточка #9 называется «Где это?»; картинка оставлена под исходным ID до решения пользователя. Оригинальные источники `education/playtown_catalog.json` (все 19 сцен), скрипты игр, общий счет и Live Space v91 сохранены без изменения; из 19 карточек в симуляторе показываются только эти десять.

## Состав патча
- Точечная динамическая замена единственной функции создания карточек и таблицы локализованных названий в `scripts/MikoMainMenu.gd`, с проверкой точного фрагмента v81.1, неизменного в v82–v93.
- Новый `simulator_ui/scripts/approved_simulator_card.gd` расширяет v83 PlanetHub-card и рисует светло-голубую полупрозрачную подложку под прозрачную иллюстрацию.
- Новый `simulator_ui/scripts/approved_game_placeholder.gd` предоставляет live-space фон v91, заголовок RU/EN, кнопку возврата через `PlayTownPortal`, без игровой логики и наград.
- Три отдельные `.tscn`, привязанные к последним трём карточкам.
- Десять PNG в `simulator_ui/assets/approved_icons/`.

## Установка на Mac Godot 4.7.1
```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v94_TenSimulatorCards_ThreePlaceholders.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v94.sh | bash -s -- "$PROJECT" "$ZIP"
```

Preflight проверяет 7 исходных сцен, локальные маркеры v83/v88, зависимости card v83, live-space v91, игру PlayTownPortal, ZIP CRC/SHA и отсутствие коллизий. Делает backup локального файла MikoMainMenu рядом с Mac проектом; установка атомарная с откатом при ошибке, повторный запуск no-op. Автозапуск только Godot 4.7.1.

**Тесты:** ZIP CRC PASS; Python compile PASS; bash syntax PASS; исходная PNG alpha 640×640 PASS; structural replacement exact/idem/fail-safe PASS; synthetic install+backup+reinstall PASS; оригинальный каталог сохранён PASS. **Живой Godot 4.7.1 на Mac ещё не запускался в сборочной среде**.

Ветка — технический паспорт ZIP, не полный snapshot пользовательского Mac проекта.