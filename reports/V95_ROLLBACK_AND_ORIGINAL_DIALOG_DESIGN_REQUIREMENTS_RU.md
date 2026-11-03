# Откат v95 и согласованное направление дальнейшей интеграции диалога

Пользователь отклонил **визуальную замену** ранее согласованного экрана диалога в v95. Требование: сначала вернуть в точности дизайн до v95, затем отдельно внедрить **только диалоговую механику v93.2**, оставив старый планшет, чат, клавиатуру, цвета, размеры, компоненты и стрелку назад. Единственная разрешённая UI-перестановка — прежний пример «что напечатать», размещавшийся внутри планшета, должен быть вынесен на левую половину над персонажем как три отдельные облачные фразы; выбор облака не отправляет сообщение. Новая логика проверки должна принимать и другие смыслово верные варианты. Живой MagneticLiquid v93 только в M31 сохраняется.

Готов вспомогательный `InfiniteSpace_v95_Restore_Original_Dialog.sh`; он автоматически находит актуальную копию `InfiniteSpace_backup_before_v95_*`, созданную самим установщиком v95, сравнивает все SHA c report-файлом, делает дополнительный snapshot текущих файлов v95 и запускает **оригинальный** `rollback_v95.py` из ZIP. Код не переписывает Main.gd, другие мини-игры или карточки. Остановится, если после установки v95 какой-либо файл изменён. Вызывать на Mac:
```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v95_Full_New_Dialog_Integrated.zip"
bash "$HOME/Downloads/InfiniteSpace_v95_Restore_Original_Dialog.sh" "$PROJECT" "$ZIP"
```

Проверки helper: Bash syntax PASS; synthetic v95 install → restore exact original dialogue PASS; new v95-only modules removed PASS; Main.gd preserved PASS; safety snapshot exists PASS; repeated rollback fails safe PASS; locally changed v95 script fails safe PASS. **На реальном Mac не запускался.** Не устанавливать v95 заново после отката; будущая интеграция должна быть отдельным патчем, который не заменяет целиком `representative_dialog.gd` / `translator_tablet.gd` и не воспроизводит v95-разметку.

Ветка содержит требования и отчёт об откате, не файл полного Mac snapshot.
