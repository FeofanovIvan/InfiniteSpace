# InfiniteSpace v81.1 — исправление установки v81 после успешного отката v80

**Проблема пользователя:** `ОШИБКА v81: Не найден _process для рестайла карточек`. Откат v80 был успешным и сохранил состояние v79.1.

**Причина:** первый v81-патчер искал `func _process(delta) -> void:\n\t_advance_bubble(delta)`, хотя реальный сценарий v79.1 оборачивает вызов в `if visible and not _playing:`. Кроме того, v81 пробовал стилизовать `Button`, а существующие игровые карточки — `TextureButton`, поэтому рамки не появились бы.

## Исправление и состав v81.1

ZIP: `InfiniteSpace_v81_1_FixedSimulatorCards.zip` — 3 052 976 байт, SHA-256 `0055ec6126c0723ef41ba1be1034af9782065b0dbaa21e07e50978792f4b1ba5`.

- Полный патч **поверх установленной v79.1**, старый v81 перед ним запускать не надо.
- Новый статический фон: ровно пользовательский `Neural Cosmos in Electric Blue.png` как `res://simulator_ui/assets/simulator_neural_blue_bg.png`. Исходный `BRIDGE_TEXTURE` меняет путь к пользовательскому PNG, без создания второй подложки.
- Счётчик кристаллов: исходный `planet_hub/scripts/bottom_hud.gd`, целиком (оба измерения!) 0.80 от размера v79.1; **не** обрезка или склейка NinePatch.
- Кнопка «Назад»: 0.60 от размера v79.1.
- 19 игровых карточек: по реальным ID из `education/playtown_catalog.json` (puzzle, wardrobe, matching_pairs, animal_habitat, profession, letter_trace, word_trace, word_build, shape_build, draw_this, pick_number, buy_groceries, count_groceries, product_count, pizza, roll_ball, color_mix, build_path, piano). Для каждой создаётся **реальный экземпляр** `planet_hub/scripts/planet_card.gd` как дочерний узел существующего `TextureButton`. Верхняя область пока без изображения (с родной технической сеткой); название внизу локализуется по `MobileLocale.language` на `ru,en,fr,de,es,pt_BR`. Исходные пути к иллюстрациям сохранены в метаданных кнопки для будущей работы. Игровые сцены и свайп по `TextureButton` остаются без изменений.
- Баббл +15%, `scripts/Main.gd`, хаб, планеты, миссии, MiniGames и пользовательские ассеты не меняются.

## Установка
```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v81_1_FixedSimulatorCards.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v81_1.sh | bash -s -- "$PROJECT" "$ZIP"
```
Контроль: ZIP CRC PASS, manifest SHA PASS, Python compile PASS, bash syntax PASS, structural patch over v79.1 mock PASS, patch idempotence PASS, 19 game IDs x 6 locale tokens PASS, safe install+backup PASS, repeat no-op PASS, unknown local edit refusal PASS, no partial-write on refusal PASS. **Godot GUI/F5 на Mac не запускался из среды сборки**. Установщик запускает Godot Editor и игру.

Эта ветка содержит паспорт ZIP, а не новый полный снимок Mac-проекта.
