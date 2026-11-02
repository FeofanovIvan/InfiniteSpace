# InfiniteSpace v75 — PlanetHub / RepresentativeDialog / TranslatorTablet

Исправление относится к **существующей сцене** `planet_hub/scenes/representative_dialog.tscn`, которая включает `representative_dialog.gd`, `dialog_character.gd`, `dialog_hint.gd`, `translator_tablet.gd`. Исходная сцена и связь с кнопкой представителя в PlanetHub сохранены.

## ZIP-поставка
`InfiniteSpace_v75_PlanetHub_TranslatorTablet.zip`, 71 015 байт; SHA-256 `4216f166d278b2e21f64e3573e164737687b5dd5c3b76731a800b190aa4fc2a4`.

Точечные изменения в локальном Mac-проекте:
1. `planet_hub/scripts/representative_dialog.gd`: неоновая кнопка назад с нормальным отступом, отдельная панель планшета в правой половине с полями по краям.
2. `planet_hub/scripts/translator_tablet.gd`: двойная неоновая рамка с закруглениями, цветовая схема PlanetHub, фон переписки `chat_space_pattern.png` из пользовательского референса, крупная подсказка «Try: Hello» под историей и над вводом, возможность ограниченного вертикального перетаскивания подсказки, клавиатура занимает всё доступное пространство.
3. Язык берётся из `/root/MobileLocale`, подписка на `language_changed`; отдельные шесть кнопок выбора языка в планшете **не создаются**. Ранее существовавшие шесть раскладок, диалоговые сценарии, правила проверки ответа и данные `ChildProfileStore` сохраняются.
4. Добавлены `planet_hub/assets/chat_space_pattern.png` и исходный `chat_space_pattern.svg`.

`Main.gd`, атлас, карточки, персонажи, фоны и нижние кнопки не изменяются. Установщик `install_and_launch_v75.sh` проверяет ZIP, применяет изменения через структурные якоря только при соответствии ожидаемым исходникам, делает резервную копию, безопасен к повторному запуску, автоматически запускает импорт и Godot Editor + игру на Mac.

Проверка сборки: ZIP CRC PASS, точечный патч + идемпотентность PASS, безопасный отказ при конфликте PASS, резервное копирование PASS, сохранение локального `Main.gd` PASS, реальные файлы репозитория и пути сцены подтверждены GitHub. **Godot GUI на Mac не выполнялся из окружения сборки**; визуальный прогон выполняется после установки на Mac.

## Команда установки
```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v75_PlanetHub_TranslatorTablet.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v75.sh | bash -s -- "$PROJECT" "$ZIP"
```

**Эта ветка содержит паспорт локального патча, не полный установленный Mac snapshot.** Не подменять ею локальные файлы без ZIP.
