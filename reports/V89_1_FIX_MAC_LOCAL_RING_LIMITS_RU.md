# InfiniteSpace v89.1 — исправление ошибочной проверки лимита Андромеды

Пользователь получил ошибку v89 на Mac: `ОШИБКА v89: Лимит колец для m31 изменён в локальном файле, останавливаюсь`. Это преждевременная ошибка: исходный v89 hardcode проверял буквальную строку `"m31": 4` в `scripts/OtherSystem.gd`, хотя локальный проект может уже иметь 3 (в Андромеде только 3 обитаемые планеты). Установка v89 была прервана на preflight и ни один файл не изменился.

## Исправленная поставка

ZIP: `InfiniteSpace_v89_1_Triangulum_Rings_LocalLimits.zip`, 12 095 290 байт, SHA256 `207bf948f9d1bb001d35ceb398e0104a48404a2956720f63cc9381fb3b468389`.

- Самодостаточный ZIP, содержит неизменённые побайтно PNG `m33_p01`, `m33_p02`, `m33_p03`, `m33_p04`, `st_m33` из пользовательского `Триангулум.zip`.
- Вместо проверки точных значений отдельных лимитов используется разбор только словаря `SYSTEM_RING_COUNTS` и проверка, что все пять внешних систем имеют целые лимиты в диапазоне **1–4**. Значения **не переписываются**, а в отчёт заносится `preserved_local_ring_limits`.
- Выбор мест кольцевых искусственных орбитальных станций — только `inhabited:true`, максимум `min(local_quota, inhabited_count)`. Детерминированные seed и уникальные варианты кольцевых станций остаются.
- Солнечная система — четыре искусственных станционных кольца на обитаемых мирах (Jupiter shell удаляется как в v89), естественные кольца Сатурна не затрагиваются.
- Только `scripts/OtherSystem.gd`, `scripts/SolarSystem.gd` и пять изображений поверхности M33; `Main.gd`, атлас, другие фоны и игры не меняются.

## Установка на Mac

```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v89_1_Triangulum_Rings_LocalLimits.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v89_1.sh | bash -s -- "$PROJECT" "$ZIP"
```

Отдельный возврат `rollback_and_launch_v89_1.sh` восстанавливает локальный бэкап и проверяет SHA изменяемых файлов.

**Проверено:** ZIP CRC/SHA PASS; 5 оригинальных PNG byte-equivalent v89 PASS; лимиты m31 1,2,3,4 PASS, лимиты 0 и 5 FAIL-SAFE; idempotent patch PASS; mock install/backup/reinstall/rollback для m31=3 и 4 PASS; неизвестные изменения отклоняются до записи PASS; Main.gd untouched PASS; Python compile and bash syntax PASS. **Живой Godot Mac F5 не выполнялся**.

Ветка содержит паспорт ZIP, не полный Mac snapshot.