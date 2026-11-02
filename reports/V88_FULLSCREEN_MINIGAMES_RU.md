# InfiniteSpace v88 — все мини-игры симулятора на весь экран

**ZIP-патч:** `InfiniteSpace_v88_FullscreenMiniGames.zip`, **6288 байт**, SHA-256 `73e5b60e3b557a115a91ce4377defb3c8a58a7774a2bfae7ed6e773b6d5f932b`.

## Причина
До v88 `scripts/MikoMainMenu.gd` выводил игры через `SubViewportContainer` с фиксированным `SubViewport.size = Vector2i(1536,768)` и:
```gdscript
var playtown_scale = minf(view.x / 1536.0, view.y / 768.0)
_viewport_container.scale = Vector2.ONE * playtown_scale
_viewport_container.size = Vector2(1536.0, 768.0)
_viewport_container.position = (view - _viewport_container.size * playtown_scale) * 0.5
```
Это давало "окно внутри симулятора" с полосами при иных соотношениях сторон.

## Новая логика
Точечный патч `scripts/MikoMainMenu.gd`:
- установить `SubViewportContainer.stretch = true`, `stretch_shrink = 1`;
- удалить фиксированную ручную установку `SubViewport.size = Vector2i(1536,768)` (при stretch она управляется контейнером);
- для игрового контейнера задать `scale=Vector2.ONE`, `position=Vector2.ZERO`, `size=view` — без изменения пропорций или центрирования;
- добавить непрозрачную полноэкранную подложку **внутри игрового слоя** (не затрагивает симулятор при просмотре карточек) для предотвращения просвечивания меню под прозрачными играми;
- сохранить существующие `_open_game`, `_return_to_cards`, `PlayTownPortal`, начисление кристаллов, 19 карточек, Баббла и кнопку возврата.

Эта версия не меняет статичные фоны отдельных игр и не исправляет индивидуальные игры с жёстко заданными координатами — это следующий этап только по запросу. Так визуально каждая игра открывается на **весь экран**, но технически остаётся в настоящем `SubViewport` (для совместимости с первоначальной игровой логикой и обработкой ввода). Godot 4.7 `SubViewportContainer.stretch` автоматически подстраивает разрешение к размерам контейнера.

## Установка (Mac после v83..v87)
```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v88_FullscreenMiniGames.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v88.sh | bash -s -- "$PROJECT" "$ZIP"
```
Установщик обновляет **только** `scripts/MikoMainMenu.gd` по точным структурным якорям, делает резервную копию рядом с локальным проектом, пишет SHA и отчёт, атомарно устанавливает и откатывает при ошибке. На несовместимой версии отказывается от записи. При повторной установке ничего не меняет. Готов к запуску Godot Editor+игры на Mac.

## Тесты и ограничения
Python 3 compile PASS; bash syntax PASS; ZIP CRC and manifest SHA PASS; структурный патч/idempotence PASS; unknown source refusal PASS; backup/atomic install/reinstall PASS; сохранение локального `Main.gd` PASS; четыре исходных якоря сверены непосредственно с `scripts/MikoMainMenu.gd` в GitHub. Полный Mac Godot F5/сенсорные проверки не выполнялись из сборочной среды.

**Ветка содержит отчёт ZIP-патча, не заменяет установленный Mac-снимок проекта.**
