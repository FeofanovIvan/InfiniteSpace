# InfiniteSpace v91 — настоящий космос из открытого мира в симуляторе и пазле

Исправление по просьбе пользователя: v90.1 ошибочно подменил полётный космос статичной картинкой, поэтому цвета, размеры звёзд, туманности и пролетающие метеоры не соответствовали открытой игре.

**Патч ZIP:** `InfiniteSpace_v91_Real_Flight_Space_Simulator_Puzzle.zip`, 8.8 КБ, SHA-256 `fc2add26d40d03c14b77e206919936fdf6c35185856bdbe775acead8cd6ecd15`.

Теперь общий компонент `simulator_ui/scripts/real_space_background.gd` создаёт настоящие игровые слои из того же исходного кода:
- `res://scripts/Starfield.gd` — оригинальный MultiMesh звёзд (3 расстояния, реальные цвета/размеры, параллакс);
- `res://scripts/FarPlasma.gd` + `res://shaders/far_plasma.gdshader` — два оригинальных экземпляра туманностей для повышенной плотности, не имитация PNG;
- `res://scripts/DistantEvents.gd` — исходные мерцания и анимированные метеоры;
- `Color(0.0015,0.003,0.009,1)` — цвет фона из `project.godot`.

Патч точечно меняет только `scripts/MikoMainMenu.gd` (источник его фона) и `education/playtown/src/features/puzzle/puzzle_game.gd` (источник фона пазла) и добавляет новый компонент. Оригинальные Starfield/FarPlasma/DistantEvents, Main.gd, другие мини-игры, награды, кнопки и счёт кристаллов не меняются.

Работает во время паузы игрового мира (`PROCESS_MODE_ALWAYS`), без копирования игрового корабля/планет/астероидов в мини-игру. Пазл остаётся полноэкранным.

Патч поверх v90 либо v90.1 (полноэкранный симулятор v88). Старая картинка остаётся физически на диске ради совместимости, но экраны пазла и каталога больше её не показывают. Installer preflight проверяет ожидаемые блоки, ресурсы, SHA+ZIP CRC, резервное копирование, атомарную запись, rollback on exception, idempotence, защиту от неизвестных локальных правок.

## Установка

```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v91_Real_Flight_Space_Simulator_Puzzle.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v91.sh | bash -s -- "$PROJECT" "$ZIP"
```

**Тесты:** Python compile PASS; bash syntax PASS; ZIP integrity PASS; structural patches PASS; mock install+backup+reinstall PASS; incompatibility fail-safe PASS. **Не проверено:** реальный GPU рендер на Mac Godot 4.7.1, особенности мобильного FPS.

Ветка является отчётом о тестированном локальном патче, не полным snapshot Mac-проекта.
