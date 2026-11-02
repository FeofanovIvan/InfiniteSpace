# InfiniteSpace v82 — исправление формы счётчика и карточек симулятора

ZIP: `InfiniteSpace_v82_PlanetHubCounter_CardsLayout.zip`, 7421 байт, SHA256 `549854eae56cca99726de3aa90565a0fcc4994f719f28c876ff217d9a1d05b0b`.

**Проблема**: v81.1 уменьшал дочерний HUD изменением `_hub_counter.size = Vector2(1680*counter_s,158*counter_s)`, но родной `planet_hub/scripts/bottom_hud.gd` создаёт `NinePatchRect` с неизменными margins 66px (left/right), 44px (top/bottom). Поэтому форма капсулы в симуляторе деформировалась, появлялись острые «наросты» на торцах. Пользователь прислал скриншоты, на которых это видно. Исправление — не реконструкция PNG.

## Изменено

- **Только** `scripts/MikoMainMenu.gd` плюс новый `simulator_ui/scripts/simulator_game_card.gd`.
- Счётчик — всё ещё **настоящий PlanetHub** `bottom_hud.gd`, с исходными внутренними `size=Vector2(1680,158)` и NinePatch margins 66/44; только `_hub_counter.scale=Vector2.ONE * counter_s`, где `counter_s=0.80 * min(screen_h/864,screen_w/1680)`. Смещение компенсирует 643px до капсулы и 394px её ширину. Вся графика и динамический счётчик уменьшаются равномерно на 20%, без обрезки, растяжения углов и «склейки».
- Кнопка «Назад» сохраняет размер 60% от v79.1.
- Игровые карточки начинаются ниже счётчика (`cards_top >= top_y + counter_h + clearance`) и занимают доступную высоту вплоть до нижнего края; сохраняются swipe, tap и `_game_layer`.
- Новая сцена-класс через наследование `extends "res://planet_hub/scripts/planet_card.gd"`. Базовые рамка/сетка/поля остаются; `_layout_content()` через `super` выставляет единственный заголовок по центру нижней области крупнее, скрывает субтитр и описание. Другие компоненты PlanetHub не изменены.
- 19 игр, локализация ru/en/fr/de/es/pt_BR, заданный пользователем статический фон, Bubble +15%, мини-игры и все предыдущие функции сохраняются.
- Никакого изменения `Main.gd`, `bottom_hud.gd`, атласа и PNG.

## Установка

```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v82_PlanetHubCounter_CardsLayout.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v82.sh | bash -s -- "$PROJECT" "$ZIP"
```

Патч требует установленную v81.1; создаёт резервную копию рядом с Mac-проектом; atomic write + rollback on failure; abort on unfamiliar layouts or preexisting changed game card script; reinstallation no-op; Godot Editor+game auto launch.

**Тесты**: Python compile PASS; Bash syntax PASS; patch idempotence PASS; 8 screen geometries PASS; counter whole-component uniform scale PASS; game title inherited script present PASS; 19 names and 6 languages retained PASS; backup/install/repeat/refusal PASS; ZIP CRC & SHA PASS. Живой Godot F5 на Mac из сборочной среды не выполнялся.

**GitHub-ветка содержит документацию, а не копию локального Mac-проекта.**
