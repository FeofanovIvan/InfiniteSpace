# MIKA / InfiniteSpace — недостающая озвучка чисел 11–20

**Игра:** Pick Up a Number («Выбери число»).  
**Статус проверки:** в ветке `sync/current-mac-20261105` обнаружены `number_00.mp3`–`number_10.mp3` в каждом из шести языковых каталогов; `number_11.mp3`–`number_20.mp3` отсутствуют.  
**Требуется:** 60 коротких записей (10 чисел × 6 языков).

## Где записывать

Каждую цифру произнести **отдельным словом**, без фраз «сколько здесь», «молодец» и т. д. Сохранить MP3:

```
res://learning/audio/voice/ru/numbers/number_11.mp3
res://learning/audio/voice/en/numbers/number_11.mp3
res://learning/audio/voice/pt/numbers/number_11.mp3
res://learning/audio/voice/es/numbers/number_11.mp3
res://learning/audio/voice/fr/numbers/number_11.mp3
res://learning/audio/voice/de/numbers/number_11.mp3
```

Продолжить аналогично с `number_12.mp3` до `number_20.mp3` в каждом каталоге.

**Важно:** язык интерфейса `pt_BR` соответствует аудиокаталогу `pt`. При записи желательно соблюдать громкость и тембр существующих `number_01.mp3`–`number_10.mp3` соответствующего языка. Не заменять существующие файлы.

## Текст для диктора

| Число | RU | EN | PT-BR | ES | FR | DE |
|---|---|---|---|---|---|---|
| 11 | одиннадцать | eleven | onze | once | onze | elf |
| 12 | двенадцать | twelve | doze | doce | douze | zwölf |
| 13 | тринадцать | thirteen | treze | trece | treize | dreizehn |
| 14 | четырнадцать | fourteen | catorze | catorce | quatorze | vierzehn |
| 15 | пятнадцать | fifteen | quinze | quince | quinze | fünfzehn |
| 16 | шестнадцать | sixteen | dezesseis | dieciséis | seize | sechzehn |
| 17 | семнадцать | seventeen | dezessete | diecisiete | dix-sept | siebzehn |
| 18 | восемнадцать | eighteen | dezoito | dieciocho | dix-huit | achtzehn |
| 19 | девятнадцать | nineteen | dezenove | diecinueve | dix-neuf | neunzehn |
| 20 | двадцать | twenty | vinte | veinte | vingt | zwanzig |

## Работа игры до появления файлов

Скрипт `mika_count_pick_native_v1_2.gd` загружает соответствующее число 11–20 **только если файл реально существует**. Иначе озвучку числа пропускает. **Он не произносит «десять» вместо одиннадцати–двадцати.** Иллюстрации, выбор правильного ответа, звуковые эффекты и похвала продолжают работать.

После добавления звуков по указанным путям никаких правок этого игрового скрипта не нужно. Если позже потребуется 11–20 также в *Write a Number* и других играх, нужно отдельно расширить `LanguageService.get_number_voice()`: сейчас общий сервис ограничивает его `clampi(number, 0, 10)`.

## Учёт готовности

Подробная ведомость: `VOICE_TODO_Pick_Number_11_20.csv` рядом с этим файлом. В ней 60 строк: язык, номер, ожидаемое произношение, путь, статус `MISSING`. Отмечайте готовые записи, меняя статус на `RECORDED`. Это проектная ведомость, не аудиофайл.
