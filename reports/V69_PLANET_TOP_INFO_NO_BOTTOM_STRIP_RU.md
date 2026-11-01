# InfiniteSpace v69 — верхняя панель планеты/станции, прозрачный нижний HUD

Локальный Mac ZIP: `InfiniteSpace_v69_TopInfo_NoBottomStrip.zip`, SHA-256 `3b450cdaafa7997e55ce5f2ac86740aa413ffc51397684c9a62f273b8d42684c` (15 271 байт).

- В `planet_hub/scripts/planet_hub_overlay.gd` хирургически добавляется верхняя панель; удаляется только отдельная полупрозрачная полоса под нижним HUD; фоновый затемняющий слой экранов не меняется.
- Новый `planet_hub/scripts/top_info_panel.gd`: название планеты/станции, штатный атласный эскиз планеты `visual_asset` или реальный спрайт станции из `assets/story`, форма жизни либо «Жизнь не обнаружена», название системы и компактная процедурная схема системы из данных атласа. Шесть языков (ru/en/fr/de/es/pt_BR), текущая обитаемость определяется `inhabited`, раса — `planet_hub/data/representatives.json`.
- Предотвращение подстановки общего фона с изображением станции на любой планете: `BACKGROUND_ROOT + system_id` и `default.png` разрешены только для станций. Локальные картинки по ID планет **не перезаписываются**. В backup создаётся `V69_BACKGROUND_AUDIT.json` со списком действительных фонов; картинку с уже нарисованной станцией в dedicated asset необходимо сверить визуально.
- Не заменяется `scripts/Main.gd`, `atlas/world_atlas.json`, `planet_hub/scripts/bottom_hud.gd`, изображения или старые патчи v65/v68.
- Установщик `install_and_launch_v69.sh` после успешной установки вызывает импорт Godot headless (когда найден Godot) и открывает редактор и игру. Лог импорта: `~/Downloads/InfiniteSpace_v69_Godot_check.log`.
- Тесты локальной сборки: ZIP integrity PASS, v61 fixture transformation + idempotency PASS, preservation local v65 code PASS, incompatible overlay refusal PASS, 6 locales/pure atlas data PASS, backup and reinstall PASS, local image and Main preservation PASS, conflict refusal PASS. Реальный Godot runtime на Mac не проверен (запускается на машине пользователя).

**Ветка хранит паспорт патча, не отражает реальный локальный v65/v68 и не является полным installed snapshot.** Игровые изменения доставляются через ZIP и применяются только поверх актуального локального проекта.
