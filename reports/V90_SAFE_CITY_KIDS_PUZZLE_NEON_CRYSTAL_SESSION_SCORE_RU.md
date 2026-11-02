# InfiniteSpace v90 — первая мини-игра «Пазл» из Safe City Kids

Пользователь напомнил, что исходный Safe City Kids есть на GitHub. Подтверждено: **точная перенесённая копия игры уже находится в InfiniteSpace**: `education/playtown/src/features/puzzle/puzzle_game.gd`, использует `education/playtown/scenes/features/puzzle/puzzle_game.tscn`, `GameScorePanel`, `GameExitButton`, `GameState`.

## ZIP

`InfiniteSpace_v90_Puzzle_Neon_CrystalHUD.zip` — **8099 байт**, SHA-256 `fc97e8ca7bee1f6461e63634a8171bb13a2b15e8d55ec2b9b48d66ebf5800420`.

Патч изменяет **только** `education/playtown/src/features/puzzle/puzzle_game.gd` в локальном Mac InfiniteSpace, не затрагивая отдельный репозиторий Safe City Kids.

- Фон: тот же `res://simulator_ui/assets/simulator_neural_blue_bg.png`, что установлен в каталоге симулятора.
- Игровое поле: нежно-голубой `#d9f2ff` вместо бежевого/оранжевого, контур тёмно-синий `#0a3562`, новая тень.
- Кнопка выхода: неоновый тёмно-синий Button с прежней программной стрелкой `res://simulator_ui/back_arrow_glyph.gd` вместо общего PlayTown `GameExitButton` с домиком; сигнал выхода через `SFX.transition_to_scene(back_scene_path)` сохраняется и перехватывается существующим `PlayTownPortal`.
- Очки: оригинальный `GameScorePanel` отображал `GameState.get_coin_balance()` (суммарные монеты, на экране могло быть 51), и подписывался на глобальное изменение. В пазле он заменяется локальным компонентом с изображением `res://planet_hub/assets/v68_neon/crystal_reference.png` и **отображением `score` текущего запуска, начиная с 0**. Общий `GameScorePanel` для других игр не меняется.
- Награды: единственный вызов `GameState.add_coins(1)` за правильно поставленный кусочек остаётся. Через сигнал `coin_balance_changed` и существующий `MikoMainMenu._on_coins_changed` награда зарабатывается и поступает в общий баланс; лимит отображаемой ёмкости симулятора `mini(50,...)` сохранён. Играть и зарабатывать очки можно после достижения 50; проблему хранения/переноса наград выше 50 не переписывали.
- Остальные 18 игр, карточки, Баббл, HUD, `Main.gd`, файл атласа и Safe City Kids не изменяются.

## Установка

```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v90_Puzzle_Neon_CrystalHUD.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v90.sh | bash -s -- "$PROJECT" "$ZIP"
```

Установщик проверяет CRC ZIP, SHA скрипта, наличие ресурсов, совпадение ожидаемых текстовых якорей; делает локальную резервную копию `education/playtown/src/features/puzzle/puzzle_game.gd` рядом с Mac-проектом, атомарно заменяет с восстановлением при сбое. Поддерживает повторный запуск, не обращается к `/mnt/data` на Mac. Запускает Godot Editor+игру, сохраняет лог импорта в Downloads.

**Тесты:** 12 якорей сопоставлены с реальным исходником `puzzle_game.gd` в GitHub, structural patch PASS, idempotence PASS, локальный score / отсутствие общего Panel PASS, неизменность единственного начисления наград PASS, Python compile PASS, shell syntax PASS, ZIP CRC/SHA PASS, mock install/backups/retry PASS, conflict fail-safe PASS. **Godot F5 непосредственно на Mac пока не проверен.**

Ветка — отчёт о ZIP, а не замена локального установленного проекта.