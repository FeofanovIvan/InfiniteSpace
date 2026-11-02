# InfiniteSpace v92 — пианино в стиле космического симулятора

ZIP: `InfiniteSpace_v92_Piano_Cosmos_CrystalLessons.zip`; SHA-256 `87f488df6b9d172ca4f92552b50d6d4f7a2d7766c8c24c6d3c76c4aef145a3a0`, около 9 KB.

Исходник первой мини-игры Safe City Kids уже импортирован в InfiniteSpace. Текущие проверенные исходники пианино: `education/playtown/src/features/piano/piano_game.gd` и `piano_keyboard.gd`.

**Изменяется только `education/playtown/src/features/piano/piano_game.gd`**; клавиатура не переписывается.

- **Фон**: тот же живой оригинальный космос, что в симуляторе и пазле v91: `simulator_ui/scripts/real_space_background.gd`, который включает реальные Starfield/FarPlasma/DistantEvents, не статичную PNG.
- **Корпус пианино**: молочный `#fdf8f3` и фиолетовый `#744ab0`, тень в гамме лаванды; исходные чёрные/белые клавиши, звуки и цвета игровых клавиш без изменений.
- **Песни**: основной текст `#ffffff` с тёмно-фиолетовой обводкой, выделенный слог `#eadcff`, крупные верхние ноты белые с `#6c43a4` обводкой, музыкальные символы бело-фиолетовые.
- **Выход**: один неоновый голубой Back, как в пазле, вместо старого дома; внешняя кнопка в оболочке полноэкранной мини-игры скрывается на время пианино и восстанавливается при выходе.
- **Счётчик**: кристалл от PlanetHub `planet_hub/assets/v68_neon/crystal_reference.png` в панели справа от Back, 0 при каждом новом заходе в пианино, накопление в рамках одного визита по разным песням.
- **Очки**: **+1 только за правильно нажатую живым игроком ноту в PlayMode.GUIDE**, после проверки с `selected_song.events[event_index].note`; неправильные ноты, демонстрационная проигрываемая музыка PlayMode.DEMO и свободная игра PlayMode.FREE ничего не начисляют. За правильную ноту вызывается единственный `GameState.add_coins(1)`, что автоматически передаёт награду в общий счётчик через `MikoMainMenu._on_coins_changed`. Механика ёмкости бака до 50 остаётся прежней.
- Не меняются песни, клавиатура, функции синтеза/звуков, 18 других мини-игр, Main.gd, PlanetHub, сохранение языка, Bubble, starfield.

## Установка после v91

```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v92_Piano_Cosmos_CrystalLessons.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v92.sh | bash -s -- "$PROJECT" "$ZIP"
```

Installer сверяет исходные якоря реально существующего `piano_game.gd` из GitHub ветки v91, проверяет ресурсы, CRC и SHA, делает бэкап рядом с Mac проектом, сохраняет все локальные изменения вне изменяемых фрагментов, атомарно записывает, откатывает при сбое и безопасен при повторном применении. Не устанавливать поверх отсутствующего v91.

**Проверки:** все 15 точных фрагментов проверены по реальному GitHub исходнику и найдены ровно по разу; Python compile PASS; bash -n PASS; patch structural PASS; idempotence PASS; fail-safe unknown local modification PASS; fail-safe existing reward logic PASS; synthetic install/backups/reinstall PASS; missing v91 cosmos fail-safe PASS; ZIP CRC PASS. **Godot 4.7.1 GUI на Mac в сборочной среде не запускался**, поэтому визуальный результат и ввод клавиш необходимо проверить после установки.

Ветка содержит паспорт локального ZIP, не заменяет рабочую версию Mac проекта.
