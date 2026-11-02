# InfiniteSpace v79.1 — исправление ошибки macOS [Errno 30] Read-only file system: '/mnt'

## Причина
Скрипт `patch_v79.py` из ZIP v79 случайно содержал две строки, перенесённые из окружения подготовки:

```python
OUT = Path('/mnt/data/v79_build')
OUT.mkdir(parents=True, exist_ok=True)
```

При запуске на Mac вторая строка пытается создать `/mnt/data/v79_build` и падает **до любых изменений игрового проекта**.

## Исправление
Новая ZIP-поставка `InfiniteSpace_v79_1_Fix_Mac_ReadOnly_Mnt.zip`, 6184 байта, SHA-256 `d9cb8891ae3eae9cdf966db49a3860e6b3fa90dcfc2138262b980a9c8d394525`. Удалены строки `OUT`; установщик пользуется только оригинальным `$TMPDIR` и относительными путями внутри пользовательского Godot-проекта, резервная копия располагается рядом с проектом. Полные игровые изменения v79 включены — **ставить v79 предварительно не нужно**.

## Mac установка
```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v79_1_Fix_Mac_ReadOnly_Mnt.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v79_1.sh | bash -s -- "$PROJECT" "$ZIP"
```

## Проверка
ZIP CRC PASS; SHA патчера PASS; Python compile PASS; bash syntax PASS; локальная тестовая установка v78→v79.1 PASS; резервная копия PASS; idempotent repeat PASS; conflict refusal PASS; `scripts/Main.gd` не затронут PASS. Godot GUI не запускался в контейнере, установщик запускает Godot Editor+игру на Mac и записывает лог в Downloads.

Ветка GitHub содержит **паспорт ZIP**, не подменяет локальный установленный snapshot пользователя.
