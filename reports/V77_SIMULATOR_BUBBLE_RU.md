# InfiniteSpace v77 — симулятор, кнопки PlanetHub, анимированный Баббл

**ZIP-поставка:** `InfiniteSpace_v77_Simulator_Bubble_Patch.zip`, размер **353 546 байт**, SHA256 `84902ede350f073009ddc02b9b5f2afed6cb93c4f8c4607bfe7af4eaf3d87ed9`.

Основа: локальная версия Mac после v76.1. GitHub-ветка — паспорт локального патча, **не** полный installed snapshot и **не** перенос локальных изменений v65-v76 на базовую ветку.

## Затронуто

- `scripts/RightStatusHUD.gd`: кнопка `MikoMainMenu` в открытом космосе получает `res://planet_hub/assets/v68_neon/simulator_badge.png` (утверждённый шлем вместо ракетного корабля). Сигнал открытия меню не меняется; подсказка `planet_simulator`.
- `scripts/MikoMainMenu.gd`: выход из симулятора слева — `Button` в голубом неоновом стиле и программная толстая стрелка из `res://simulator_ui/back_arrow_glyph.gd`, аналогично PlanetHub v76. В мини-играх внутренний возврат тоже получает этот стиль. Справа — `NinePatchRect` капсула кристаллов из PlanetHub v68, оригинальная картинка кристалла и **живое** число. Собаки больше нет: `AnimatedSprite2D` заменяется `Node2D` со сценой Баббла, который идёт/плывёт по низу экрана, разворачивается у границ. Текущий клик по питомцу по-прежнему открывает существующий PetHome, без рефакторинга образовательных мини-игр.
- Новое `simulator_ui/bubble/`: содержимое **пользовательского** `Bubble_Walk_Standalone_Godot4.zip` (сцена `bubble.tscn`, скрипт `bubble.gd`, `bubble_metaball.gdshader`, PNG глаз и рта), с переписанными только путями `res://`. Демонстрационная сцена управления самостоятельного проекта не переносится. Удалена глобальная `class_name BubbleCreature`, чтобы не конфликтовать с другими играми.
- Пользовательские v68-ассеты `simulator_badge.png`, `crystal_reference.png`, `crystals_panel.png` добавляются **только если отсутствуют**; имеющиеся картинки пользователя сохраняются.

Не меняются `scripts/Main.gd`, атлас, `planet_hub/scripts/bottom_hud.gd`, миссии, карточки, диалоги и настройки.

## Установка
```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v77_Simulator_Bubble_Patch.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v77.sh | bash -s -- "$PROJECT" "$ZIP"
```

Установщик проверяет CRC/SHA всех файлов, проводит preflight до записи, останавливается при несовместимых исходниках, создаёт резервную копию, пишет `V77_INSTALL_REPORT.json`, поддерживает идемпотентность и выполняет атомарную замену с откатом. После успешной установки открывает Godot Editor и игру, сохраняет лог Godot в `~/Downloads/InfiniteSpace_v77_Godot_check.log`.

**Проверки сборки:** ZIP CRC/SHA PASS; переназначение путей Bubble PASS; устранение глобальной коллизии GDScript PASS; script Python compile PASS; bash syntax PASS; структурная замена и идемпотентность PASS; end-to-end установка/backup/повтор PASS; отказ при чужой модификации Bubble PASS; сохранность Main.gd PASS. **Живой Godot F5 на Mac из сборочного контейнера не проводился**; импорт и визуальные проверки проходят на Mac после запуска установщика.

Область следующих игровых улучшений: возможно позже по отдельному запросу заменить связь клика Баббла с прежним PetHome (сейчас связь сохранена).
