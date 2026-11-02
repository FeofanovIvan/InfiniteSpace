# InfiniteSpace v86 — обитаемые миры и станция галактики Барнарда

Принят пользовательский архив `Барнарда.zip`, в нём шесть оригинальных PNG. Имена архива (после восстановления кодировки CP437→UTF-8) сопоставлены **строго по русским названиям из атласа**, без догадок:

| Название | ID | Ресурс в PlanetHub |
|---|---|---|
| Археон | `ngc6822_p01` | `res://planet_hub/backgrounds/ngc6822_p01.png` |
| Квария | `ngc6822_p02` | `res://planet_hub/backgrounds/ngc6822_p02.png` |
| Нокта | `ngc6822_p03` | `res://planet_hub/backgrounds/ngc6822_p03.png` |
| Ферра | `ngc6822_p04` | `res://planet_hub/backgrounds/ngc6822_p04.png` |
| Руна | `ngc6822_p06` | `res://planet_hub/backgrounds/ngc6822_p06.png` |
| Голова Титана | `st_ngc6822` | `res://planet_hub/backgrounds/st_ngc6822.png` |

Путь выбора уже предусмотрен в `planet_hub/scripts/planet_hub_overlay.gd`: `planet_hub/backgrounds/<id>.png`. Поэтому скрипты, атлас, `Main.gd`, png космических планет, кристаллы и персонажи **не меняются**. Необитаемые объекты `ngc6822_p05` Дуна, `ngc6822_p07` Геода, `ngc6822_p08` Хрона и их общие фоны из v85 не изменяются.

ZIP: `InfiniteSpace_v86_Barnard_Inhabited_Station.zip`, 15 576 510 байт, SHA-256 `89f23dbcdcbe2afba74bb992d78795891000da45a16eb0965a2192a12fc6f345`.
Обзор: `InfiniteSpace_v86_Barnard_Images_Overview.jpg`.

Установка на Mac:

```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v86_Barnard_Inhabited_Station.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v86.sh | bash -s -- "$PROJECT" "$ZIP"
```

Бэкап оригинальных PNG с фиксацией SHA перед заменой, атомарная запись, rollback при ошибке и отдельная команда `rollback_and_launch_v86.sh` (сверка изменений перед откатом, сохранение состояния до отката). Godot 4.7.1 после установки открывается через `open -na`. Скрипт не содержит Mac-invalid `/mnt/data` путей.

Проверки: 6 PNG source-byte identity+SHA+PNG integrity PASS, ZIP CRC PASS, bash syntax PASS, Python compile PASS, тестовая установка PASS, сохранение неперезаписанных ресурсов v85 и `Main.gd` PASS, идемпотентность PASS, откат PASS, конфликт атласа/символических ссылок/ручной пост-установочной правки FAIL-SAFE PASS. Godot F5 в сборочной среде не запускался.

**Данная ветка содержит паспорт тестированного локального ZIP, а не snapshot Mac проекта пользователя.**