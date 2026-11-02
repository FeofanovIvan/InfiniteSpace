# InfiniteSpace v87 — обитаемые планеты и станция Андромеды

**Источник:** предоставленный пользователем `Андромеда.zip`. Архив содержит 4 PNG (не считая macOS metadata); имена однозначно соотнесены по `name_ru` в `atlas/world_atlas.json`. Станция исходно использует Unicode NFD вариант `Перевёрнутая пирамида.png`, при сопоставлении нормализовано NFC, пиксели не изменялись.

| Название | Тип | ID | Куда устанавливается |
|---|---|---|---|
| Фазис | обитаемая | `m31_p03` | `planet_hub/backgrounds/m31_p03.png` |
| Синта | обитаемая | `m31_p05` | `planet_hub/backgrounds/m31_p05.png` |
| Геона | обитаемая | `m31_p06` | `planet_hub/backgrounds/m31_p06.png` |
| Перевёрнутая пирамида | станция | `st_m31` | `planet_hub/backgrounds/st_m31.png` |

**Пакет:** `InfiniteSpace_v87_Andromeda_Inhabited_Station.zip` (8 941 173 байта), SHA256 `d2d5bf45fef2ab0959f9c73ac52c34e6c6d06fe58e5c42b9e7ed179718cc0262`.

**Обзор:** `InfiniteSpace_v87_Andromeda_Images_Overview.jpg`.

Необитаемые `m31_p01` Люмена, `m31_p02` Гравис, `m31_p04` Гелион, `m31_p07` Резона, `m31_p08` Квантия остаются на назначениях общих фонов из v85. Другие системы, скрипты, галактические объекты в открытом космосе, атлас и `scripts/Main.gd` не изменяются. Изображения устанавливаются **только для сцен поверхности PlanetHub**; космические превью и навигацию не менять.

## Установка на Mac

```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v87_Andromeda_Inhabited_Station.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v87.sh | bash -s -- "$PROJECT" "$ZIP"
```

В составе ZIP — `install_v87.py`, `rollback_v87.py`, `install_and_launch_v87.sh`, `rollback_and_launch_v87.sh`, `manifest_v87.json`, `README_RU.md` и 4 PNG. Установщик использует локальный Godot-проект, до записи сверяет атлас по ID/названиям/статусу обитаемости, делает резервные копии PNG рядом с проектом, записывает атомарно и поддерживает rollback. На повторной установке no-op. Не обращается к `/mnt/data` на Mac.

**Проверки:** ZIP CRC PASS, SHA/SIGNATURE PNG PASS, Python compile PASS, Bash syntax PASS, successful synthetic install+backup PASS, idempotent reinstall PASS, rollback PASS, rejects bad atlas PASS, symlink fail-safe PASS, preserves `scripts/Main.gd` и фон `m31_p01` PASS. Реальный GUI Godot/F5 на Mac не исполнялся в среде сборки.

Эта ветка — **отчёт о ZIP-патче**, а не замена локальной рабочей ветки пользователя.
