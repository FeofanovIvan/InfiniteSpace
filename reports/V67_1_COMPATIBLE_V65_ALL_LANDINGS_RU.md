# InfiniteSpace v67.1 — совместимый патч для установленной v65

Предыдущая v67 не установилась: локальный `scripts/Main.gd` из v65 имеет Git blob `b619d2d9827ed1fa928aa53fc4b1ba040cda58d5`, а установщик ожидал `f418cc05296dd1736d35f9f82990d31d7c975241`.

**Решение:** устанавливать изменения только в `atlas/world_atlas.json` текущего локального проекта. Программа не копирует atlas из ветки и **не переписывает `Main.gd`**, поэтому v65-автопосадка станций и LMC-изображения сохраняются. Установщик проверяет 48 планет, 24 обитаемые, точное изменение только `landing=landing` и `landable=true`, создаёт backup, повторный запуск безопасен.

Ветка хранит схему v67.1 поверх удалённой v66 — НЕ полную копию локальной v65, которая пока отсутствует в GitHub. Нельзя заменять `Main.gd` пользователя из ветки.

ZIP: `InfiniteSpace_v67_1_Patch_v65_Compatible_Landing.zip`; SHA-256 `6385f6af4a9e4566cef940d847313a419fc778792ddfd6e734fd9f697b3570e6`. Комплект: `install_v67_1.sh`, `patch_v67_1.py`, `README_RU.md`, `tests/test_patch_v67_1.py`, `MANIFEST.sha256`. Тесты Python: 4 PASS; ZIP integrity PASS; end-to-end установка PASS; повторный запуск PASS; контроль неизменности Main PASS. Godot F5 на Mac не выполнялся.
