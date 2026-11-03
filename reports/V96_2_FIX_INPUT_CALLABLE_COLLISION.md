# InfiniteSpace v96.2 — исправление ошибки `Cannot find member "text" in base "Callable"`

После v96.1 на Mac Godot 4.7.1 пользователь получил ошибки компиляции в строках 406, 495, 500.

**Корневая причина:** исходный UI объявляет `var _input: LineEdit`, а v76 добавил в тот же GDScript `func _input(event: InputEvent) -> void`. Имя поля LineEdit конфликтует с методом ввода Godot; обращение `_input.text` иногда разрешается как свойство Callable.

**Исправление v96.2:** в единственном файле `planet_hub/scripts/translator_tablet.gd` поле и обращения к нему переименовываются в `_message_input`; нативная функция `_input(event)` сохраняется полностью, включая touch/mouse scrolling. Не меняются существующий планшет, цвета, чат, индикатор «печатает…», анимация магнитного существа, три нижних облачка, профиль и новая логика диалога. Файл Main.gd не трогается.

**ZIP**: `InfiniteSpace_v96_2_Fix_Tablet_Input_Callable.zip` (7598 bytes, SHA-256 `713496149e6a87ad06a5145c36c428979cdd180d61aa2b248038439adba2712b`).

Установка поверх **уже установленной v96.1**:
```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v96_2_Fix_Tablet_Input_Callable.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v96_2.sh | bash -s -- "$PROJECT" "$ZIP"
```

ZIP содержит `install_v96_2.py`, `rollback_v96_2.py`, обе bash-обёртки, manifest SHA, README. Файлы без иных изменений, бэкап рядом с Mac-проектом `InfiniteSpace_backup_before_v96_2_*`.

**Проверки:** Python syntax PASS, bash -n PASS, ZIP CRC PASS, SHA installer PASS, synthetic model of actual field/method collision PASS, patch only LineEdit references PASS, preserve `func _input` PASS, idempotent apply PASS, mock install/backup/rollback PASS, unknown-version/structure blocked PASS. **Реальный Godot 4.7.1 на Mac недоступен в нашей среде**, поэтому компиляция проекта не подтверждена.

Ветка содержит технический отчёт и сведения о локальном ZIP, не полный источник проекта.
