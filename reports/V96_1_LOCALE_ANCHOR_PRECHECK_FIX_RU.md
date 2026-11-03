# InfiniteSpace v96.1 — исправление «синхронизация языка диалога: 0 совпадений»

## Причина
Пользователь откатил v95 успешно и затем запустил v96, который остановился **до записи файлов** с ошибкой:
`ОШИБКА v96: синхронизация языка диалога: ожидалось одно совпадение, найдено 0; файлы не менялись`.

В `v75` обработчик `_on_global_locale_changed` заканчивался перед `_on_hint_drag`. Патч `v76` добавил `_input(event: InputEvent)` для обработки скролла чата **между ними**, поэтому хрупкая строковая замена `v96`, ожидавшая точную смежность, закономерно провалилась.

**Исправление:** в `v96.1` patcher находит тело функции `_on_global_locale_changed(lang: String) -> void` по её собственным границам (regex с отдельным якорем начала следующей функции) и добавляет локальный сброс диалога после существующего `_refresh_hint()`, не меняя `_input` и `_on_hint_drag`.

## ZIP
`InfiniteSpace_v96_1_OriginalDesign_Clouds_LocaleFix.zip`, 45 472 байта,
SHA-256 `5c86d1e869c0734521f27c625425e16c570f733e45404c3703204488606acda5`.
Самодостаточный патч, не требующий установки v96. Содержит те же **8 исходных ресурсов**, что v96, точечную интеграцию новой логики в старый UI, три облачка в нижней левой части, сохранение MagneticLiquid v93.

## Команда для Mac Godot 4.7.1
```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v96_1_OriginalDesign_Clouds_LocaleFix.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v96_1.sh | bash -s -- "$PROJECT" "$ZIP"
```

При успешной установке создаёт `InfiniteSpace_backup_before_v96_1_*` и имеет отдельный откат `rollback_and_launch_v96_1.sh`. **Повторный откат v95 не нужен.**

## Тесты
- Структурный тест с точным порядком обработчиков v76: `_on_global_locale_changed` → `_input` → `_on_hint_drag`, PASS.
- Встроенный скролл-обработчик `_input` остаётся в файле, PASS.
- Structural/idempotence, mock install/backup/reinstall/rollback и fail-safe при неизвестных изменениях PASS.
- Python compile, bash -n, ZIP CRC, SHA installer + 8 payload assets PASS.
- Прямой запуск Godot на Mac не выполнен.

GitHub-ветка содержит технический отчёт, а не установленные пользовательские файлы.
