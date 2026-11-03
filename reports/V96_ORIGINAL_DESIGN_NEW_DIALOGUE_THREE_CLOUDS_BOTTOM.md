# InfiniteSpace v96 — новый алгоритм диалога в сохранённом старом дизайне

После отката v95 пользователь попросил сохранить **исходный визуальный диалог v75/v76/v93 полностью** и перенести только один компонент интерфейса: подсказку `Try: Hello` из планшета в **три отдельных облачка в нижней части слева, поверх персонажа**. Выбранное облако подсвечено **жёлто-оранжевой обводкой и бело-молочным фоном**. Облака имеют динамическую ширину по тексту, лёгкий горизонтальный разброс и автоперенос.

**ZIP**: `InfiniteSpace_v96_OriginalDesign_NewDialogue_CloudsBottomLeft.zip`, 45 596 байт; SHA-256 `38a5d20a0ccf6165c5b9e0058cd114ae514eb0e8c8d3532491d61adc27437ef9`.

## Реализация
- **Не заменяем целиком** `representative_dialog.gd` и `translator_tablet.gd`: installer программно внедряет только необходимые изменения в локальные версии v75/v76/v93. В основном диалоге старые `character.position/size`, `tablet.position/size`, фон, отступы и стрелка назад сохраняются, штатный `_v93_configure_magnetic_dialog` остается.
- Планшет `translator_tablet.gd` сохраняет рисунок рамки, фоновый chat pattern, клавиатуру с жёлто-оранжевым выделением букв, сообщения, `_queue_npc` и анимированное «печатает…». Скрываются только исходная строка `Try` и ее подложка; освобождённое пространство отдаётся окну переписки (без изменения внешнего вида панели).
- В игру полностью подключается новый офлайн `dialogue_engine.gd` / `dialogue_input_matcher.gd` и исходные данные `dialogue_worlds.json`, `dialogue_phrases.json`: 54 мира, 30 обитаемых, 10 тем, 6 языков, терпимость к опечаткам и смысловым вариантам, сохранение прогресса, персональных ответов без вымышленных значений. Подсказка не отправляет сообщение автоматически, ребёнок вводит ответ сам.
- Новый `cloud_choice_button.gd` отвечает только за три независимых визуальных элемента; карточки, HUD, изображения, магнитная сцена, `Main.gd`, `project.godot`, `representative_dialog.tscn`, `dialog_character.gd`, `dialog_hint.gd` и остальные игры не меняются.
- `ChildProfileStore` обновляется до новой логики сохранения и избегает прежних демонстрационных значений. Защитный installer требует старые метки v75/v76/v93 и отвергает всё ещё установленный v95.

## Установка на Mac Godot 4.7.1

```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v96_OriginalDesign_NewDialogue_CloudsBottomLeft.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v96.sh | bash -s -- "$PROJECT" "$ZIP"
```

Делает резервную копию `InfiniteSpace_backup_before_v96_*` рядом с проектом и предоставляет `rollback_and_launch_v96.sh`. Заменяет только проверенные исходные файлы с предшествующей копией и атомарной записью. Устанавливается поверх **откаченного v95** и установленного v93. Автозапуск только для Godot 4.7.1.

**Проверки**: ZIP CRC/SHA PASS; 8 ресурсов сверено по SHA; Python syntax и Bash syntax PASS; структурные anchor patch и idempotence PASS; mock install+backup+rollback PASS; second rollback and mismatched old design fails safe PASS; Main.gd unchanged PASS. **Не проверено:** реальный Godot 4.7.1 run/UX/render на Mac; в нашей среде Godot нет.

Ветка фиксирует описание локального ZIP, не является snapshot установленного Mac проекта.
