# InfiniteSpace v76 — диалог представителя PlanetHub

ZIP-патч: `InfiniteSpace_v76_PlanetHub_Translator_Fixes.zip`, SHA-256 `f181089aad0bd0474b4a6b50aefaa0cbc855a72d55bd5dbce3c5dbc25ade669a`, 10 227 байт.

Установщик предназначен для **текущего локального Mac Godot-проекта после v75**. Действующие локальные v65–v75 не заменяются устаревшим GitHub snapshot.

Изменяет **только**:
- `planet_hub/scripts/representative_dialog.gd`: заменяет тонкий символ на собственную толстую нарисованную в Godot неоновую стрелку; убирает затемнение половины экрана с персонажем
- `planet_hub/scripts/dialog_character.gd`: убирает под персонажем голографический пьедестал, дугу и горизонтальную линию
- `planet_hub/scripts/translator_tablet.gd`: исправляет v75 race — клавиатура строилась при русском значении по умолчанию **до** чтения `MobileLocale`; после получения языка перестраивает раскладку, локализует placeholder (6 языков), усиливает подсветку следующей буквы, добавляет перетаскивание списка сообщений пальцем и мышью
- Новый `planet_hub/scripts/back_arrow_glyph.gd`: программно нарисованная неоновая стрелка, без нового изображения

Не меняет `Main.gd`, сцены посадки, атлас, фоны, персонажей, подсказку Try Hello, правила проверки ответов и настройки языков.

ZIP содержит `patch_v76.py`, `install_and_launch_v76.sh`, SHA манифест, README и тесты. Python-тесты: структурный patch/idempotence PASS; install+backup+repeat PASS; unknown source refusal PASS; ZIP CRC PASS; bash syntax PASS. Godot GUI/F5 в Linux-среде отсутствует; установщик Mac проверяет импорт, запускает редактор и игру.

Команда:
```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v76_PlanetHub_Translator_Fixes.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v76.sh | bash -s -- "$PROJECT" "$ZIP"
```

**Важно:** эта ветка — паспорт ZIP, а не установленный Mac snapshot.
