# Infinite Space v33.1 — исправление ложных «лун» (29.10.2026)

## Диагноз

На скриншоте около первой планеты LMC (Aera, `lmc_p01`) виден фиолетовый круг с белым центром. **Это не луна**: `atlas/world_atlas.json` указывает, что у `lmc_p01` **нет ни одного спутника**. Объект создаёт `scripts/OtherSystem.gd`:

```gdscript
var landmark: Node2D = LandmarkClass.new()
landmark.name = "Landmark_" + str(source["id"])
add_child(landmark)
landmark.call("configure", i, ...)
```

Сам `scripts/AtlasLandmark.gd` рисует кольцо, центральный круг, антенну и свечение — поэтому это похоже на плохо проработанный искусственный спутник.

Создание выполняется для всех восьми планет в пяти внешних системах: **40 лишних объектов**. Ещё **5** объектов создаются в тех же системах как `UniqueStationSilhouette`, накладываясь на рисунки станций.

## Исправление

Подготовлен **патч v33.1**. Из `scripts/OtherSystem.gd` удалено:
- создание `Landmark_* / AtlasLandmark` (40 объектов);
- создание `UniqueStationSilhouette_*` (5 объектов);
- отрисовка/обновление координат этих 45 объектов.

Сохранены:
- все **64 индивидуальные луны** из `moon2d/` с их орбитами;
- все **48 планет** и пять внешних солнц;
- **14** кольцевых станций во внешних системах, по 2/3/2/4/3;
- одна прежняя сюжетная станция на систему с навигационной целью;
- оригинальная Солнечная система, NPC, HUD, интро, гиперпрыжок.

`scripts/AtlasLandmark.gd` оставлен в проекте как невостребованный исходник, но в `OtherSystem` больше не инстанцируется.

## Регрессионная проверка

Проверен `InfiniteSpace_Godot_Prototype_v33_All_64_Moons.zip` плюс патч v33.1 на отдельной копии проекта.

- `tools/check_v32.py`: PASS
- `tools/check_v32_1.py`: PASS
- `tools/check_v33.py`: PASS
- `tools/check_v33_1.py`: PASS
- ZIP integrity: PASS.
- Пофайловое сравнение: **изменён только `scripts/OtherSystem.gd`**; два новых файла — `tools/check_v33_1.py`, `docs/CHANGELOG_v33_1_RU.md`.

**Godot 4.7.1 F5/render на Mac ещё не подтверждён.** Код не переносился в стабильную `main`, пока пользователь не проверит реальную отрисовку.

Связанная задача: [#2](https://github.com/FeofanovIvan/InfiniteSpace/issues/2).
