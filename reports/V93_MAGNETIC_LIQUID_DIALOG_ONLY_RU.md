# InfiniteSpace v93 — живой MagneticLiquid только в окне диалога магнитной расы

**Источник:** оригинальный пользовательский архив `InfiniteSpace_MagneticLiquid_Godot47.zip`. Из него без пересохранения/изменений скопированы:
- `res://magnetic_liquid/MagneticLiquid.tscn`
- `res://magnetic_liquid/magnetic_liquid.gd`
- `res://magnetic_liquid/magnetic_liquid.gdshader`

**ZIP:** `InfiniteSpace_v93_MagneticLiquid_DialogOnly.zip`, 13 KB, SHA-256 `945a6e53da5732b2fd2d5902747abe79ec409253d1bc93de94da9a9d54ffb27c`.

## Точный объём работы

`planet_hub/scripts/representative_dialog.gd` (один точечно обновлённый скрипт) при `configure_for_planet` заменяет только левую область изображения персонажа на экземпляр сцены при ID:
- `m31_p03` Фазис;
- `m31_p05` Синта;
- `m31_p06` Геона;
- `st_m31` Перевёрнутая пирамида.

Сверено с `planet_hub/data/representatives.json`: `race_by_system.m31 == "magnetic"`, все ID назначены магнитным PNG `13_`, `14_`, `15_`.

Новая сцена создаётся *лениво* один раз при входе в первый магнитный диалог, масштабируется по фактической области `RepresentativeCharacter` слева, размещается перед фоном, но под планшетом и стрелкой назад. Форма по умолчанию `set_form(0)`, спокойное `set_agitation(0.18)`, исходный анимированный шейдер продолжает работать при паузе игры. При открытии другого диалога живая сцена скрывается, рендер исходного `dialog_character.gd` восстанавливается. Реальный обмен сообщениями / язык / клавиатура планшета не меняются.

**Не меняются:** карточки и превью представителей PlanetHub, все изображения и их назначения, остальные расы, планшет-переводчик, Main.gd, мини-игры, Godot project.godot.

## Установка на Mac (Godot 4.7.1)
```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v93_MagneticLiquid_DialogOnly.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v93.sh | bash -s -- "$PROJECT" "$ZIP"
```

Установщик проверяет локальные v75/v76 якоря диалога, список магнитных ID в реестре, SHA пользовательских файлов, целостность ZIP и отсутствие конфликтов по именам. Создаёт backup `InfiniteSpace_backup_before_v93_*`, атомарно обновляет один GDScript и копирует три ресурса, выполняет rollback при ошибке, повторный запуск no-op. Автозапуск только найденного **Godot 4.7.1** (не 4.7.2).

**Тесты:** ZIP CRC PASS; original-resource byte identity PASS; anchor match + idempotent structural patch PASS; mock install / backup / no-op reinstall PASS; fail-safe on unknown local changes, conflicting resources or a nonmagnetic M31 PASS; Python syntax PASS; Bash syntax PASS.

**Не проверялось:** визуальная работа GPU шейдера и диалога непосредственно в Godot на Mac; загруженная пользователем сцена была независимым прототипом и не проходила engine-run test в этой среде.

Данная ветка содержит отчёт и ссылку на создаваемый ZIP-патч, но не является копией локально установленного Mac-проекта.
