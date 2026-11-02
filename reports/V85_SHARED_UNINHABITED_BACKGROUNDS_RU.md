# InfiniteSpace v85: 13 общих фонов для 24 необитаемых миров

Источник: предоставленный пользователем `Пустые(2).zip`. Подтверждено: архив содержит PNG с номерами 1–13; пользовательская таблица на 24 мира **полностью совпадает** с `atlas/world_atlas.json` ветки `release/v84-hyperspace-map-settings` — имена, ID и `inhabited:false`.

ZIP патча: `InfiniteSpace_v85_Shared_Uninhabited_Backgrounds.zip`, SHA256 `fccf9dece375c2b26e19f0f4ab049bee38a7589c3ecb495b7aac9941af6bf1d5`, 26 311 024 байта.

## Назначения

| ID | Название | № исходного PNG |
|---|---|---:|
| `mw_p04` | Сатурн | 1 |
| `mw_p05` | Уран | 5 |
| `mw_p08` | Меркурий | 2 |
| `lmc_p01` | Аэра | 5 |
| `lmc_p05` | Карбона | 7 |
| `lmc_p06` | Люкс | 4 |
| `lmc_p07` | Вентра | 6 |
| `lmc_p08` | Магнета | 5 |
| `smc_p04` | Мицела | 12 |
| `smc_p06` | Амбра | 10 |
| `smc_p07` | Силика | 11 |
| `smc_p08` | Биора | 6 |
| `ngc6822_p05` | Дуна | 11 |
| `ngc6822_p07` | Геода | 9 |
| `ngc6822_p08` | Хрона | 11 |
| `m31_p01` | Люмена | 7 |
| `m31_p02` | Гравис | 1 |
| `m31_p04` | Гелион | 9 |
| `m31_p07` | Резона | 12 |
| `m31_p08` | Квантия | 4 |
| `m33_p05` | Паралла | 11 |
| `m33_p06` | Пульса | 8 |
| `m33_p07` | Эклипса | 13 |
| `m33_p08` | Цикла | 3 |

## Установка
```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v85_Shared_Uninhabited_Backgrounds.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v85.sh | bash -s -- "$PROJECT" "$ZIP"
```

В игровом проекте 13 PNG хранятся **ровно по одному экземпляру**: `planet_hub/backgrounds/shared_uninhabited/01.png`–`13.png`. Новая таблица `planet_hub/data/uninhabited_shared_backgrounds.json` содержит 24 соответствия; `planet_hub/scripts/planet_hub_overlay.gd` загружает их с приоритетом, только при `inhabited:false` и не для станции. Старые ресурсы и `Main.gd` не трогать. В космосе изображения планет не меняются; логика посадки тоже не меняется.

Installer verifies local atlas exactly; differs => fail safe with zero changes. Payload SHA, zip CRC, preflight, backup, atomic install+rollback, idempotence and symlink defense tested in synthetic Godot project. Actual Mac Godot import/gameplay must be checked after installation. Original 13 images differ in dimensions, retained without editing. **This branch is a patch report, not a replacement for installed local Mac snapshot.**
