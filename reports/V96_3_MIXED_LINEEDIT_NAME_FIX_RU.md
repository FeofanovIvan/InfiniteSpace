# InfiniteSpace v96.3 — hotfix смешанного состояния LineEdit в планшете

**Ошибка пользователя после v96.2:** два запуска `ОШИБКА v96.2: Частично исправленный планшет — остановлено без записи`. Предыдущая ошибка Godot 4.7.1: `Cannot find member "text" in base "Callable"`, строки 406/495/500.

**Причина:** v96.1 сохранил предыдущий UI, но сгенерировал три обращения `_input.text` в новых обработчиках. Старый код может уже использовать `var _message_input: LineEdit` как имя поля, а встроенный `func _input(event: InputEvent)` всё ещё существует для свайпа и прокрутки. Установщик v96.2 не поддерживал комбинацию «новое имя поля + старые обращения» и отказался устанавливать патч.

**Исправление:** v96.3 принимает ровно одно объявление LineEdit: `var _input: LineEdit` **или** `var _message_input: LineEdit`. После проверки структуры заменяет остаточные идентификаторы `_input` на `_message_input`, возвращая точное имя встроенного события `func _input(event: InputEvent) -> void`. Идемпотентен; если одновременно объявлены два поля, останавливается без записи. Предыдущая v96.2 не вносила изменений.

**ZIP:** `InfiniteSpace_v96_3_Fix_Tablet_Input_Callable.zip`, 8097 байт. SHA-256 `9ad569c015c8ebcad66ee7315320a860629517ef1cabf459f72a55ce8d6a3eab`. Изменяет **только** `planet_hub/scripts/translator_tablet.gd`. Фон, визуальный планшет, клавиатура, облачка, typing indicator, MagneticLiquid и Main.gd не изменяются.

**Mac установка**:
```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v96_3_Fix_Tablet_Input_Callable.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v96_3.sh | bash -s -- "$PROJECT" "$ZIP"
```
Поддержан автозапуск только Godot 4.7.1 и headless-import report в `~/Downloads/InfiniteSpace_v96_3_Godot_check.log`.

**Проверки:** синтетическая локальная old/mixed/complete версия PASS; сохранение `func _input(event)` PASS; повторное применение no-op PASS; mock install+SHA backup+rollback PASS; fail-safe unknown source PASS; Python compile, Bash syntax, ZIP CRC/SHA PASS. **Без живой компиляции под Godot** в контейнере — актуальные ошибки движка проверяются на пользовательском Mac.

Ветка хранит паспорт локального исправления, не версию проекта пользователя.