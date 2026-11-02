# InfiniteSpace v89 — Треугольник, точные фоны и кольца на обитаемых мирах

**Входной архив**: `Триангулум.zip` (пользовательский, 5 PNG). Все имена распознаны через UTF-8 восстановление CP437 и Unicode NFC, сопоставлены с `atlas/world_atlas.json`. PNG перенесены побайтно:

| Файл пользователя | Атлас ID | Surface background |
|---|---|---|
| Светара.png | `m33_p01` | `planet_hub/backgrounds/m33_p01.png` |
| Орбита.png | `m33_p02` | `planet_hub/backgrounds/m33_p02.png` |
| Тессера.png | `m33_p03` | `planet_hub/backgrounds/m33_p03.png` |
| Лентис.png | `m33_p04` | `planet_hub/backgrounds/m33_p04.png` |
| Последние врата.png | `st_m33` | `planet_hub/backgrounds/st_m33.png` |

Необитаемые `m33_p05`–`m33_p08` и их общие фоны v85 не меняются.

**ZIP**: `InfiniteSpace_v89_Triangulum_Inhabited_Rings.zip` — 12 094 906 байт, SHA256 `576b6988dcaa1bc260259321a9176da98c7a8031b138ce4ab4add15aedf144a9`; обзор: `InfiniteSpace_v89_Triangulum_Overview.jpg`.

## Искусственные орбитальные кольца

`scripts/OtherSystem.gd` раньше выбирал кандидатов по `story:true` или ключевым словам в `unique`, что позволяло назначить кольцо необитаемому миру. Исправлено:
- `_planet_supports_civil_station(data)` возвращает только `bool(data.get("inhabited",false))`;
- в месте размещения и самой функции `_build_planet_orbital_ring` добавлена явная защита `inhabited:true`;
- орбиты спутников учитывают увеличение радиуса только при фактически допустимом кольце;
- выбор по seed и лимит существующей карты сохранены, максимум по системе 1–4, только уникальные обитаемые планеты:
  - LMC **2**, SMC **3**, Barnard **2**, M31 **3** (ранее конфиг 4, но обитаемых всего 3), M33 **3**.
- Солнечная система `scripts/SolarSystem.gd`: **4** искусственных орбитальных кольца на обитаемых планетах, теперь без декоративной орбитальной конструкции у Юпитера (парящая станция как идея остаётся в лоре; планета/геймплей не удаляются).
- Природные кольца Сатурна (отдельный собственный визуальный объект, НЕ орбитальная станция) не меняются.

`Main.gd`, схемы, навигация, логика посадки, сцены обитаемых миров других систем и остальной HUD не меняются.

## Установка на Mac

```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v89_Triangulum_Inhabited_Rings.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v89.sh | bash -s -- "$PROJECT" "$ZIP"
```

В ZIP также rollback:

```bash
unzip -p "$ZIP" rollback_and_launch_v89.sh | bash -s -- "$PROJECT" "$ZIP"
```

**Проверки:** архив CRC PASS; пять PNG SHA/signature PASS; изображения получены побайтно, без транскодирования PASS; scripts bash -n PASS; Python compile PASS; структурная замена и идемпотентность PASS; тестовая установка+бэкап+повторная установка+откат PASS; безопасный отказ при несовместимых исходниках PASS; `Main.gd` untouched PASS. Mac Godot GUI F5 здесь не запускается; Mac installer запускает Godot Editor и игру после установки, пишет лог.

**Ветка содержит отчёт ZIP, а не полный снимок установленного Mac-проекта.**