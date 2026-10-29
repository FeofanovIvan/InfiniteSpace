# Credits and licenses / Авторство материалов

## Включено в архив V3
- Земля: NASA Blue Marble imagery (адаптировано и уменьшено для игры), источник https://visibleearth.nasa.gov/collection/1484/blue-marble
- Меркурий, Венера, Марс, Юпитер, Сатурн, Уран, Нептун: **вложены художественные процедурные заглушки**, созданные проектом. Это **не** научные карты NASA.
- Солнце: процедурная игровая карта и шейдеры MIKO, не официальный NASA продукт.
- Кольца Сатурна: процедурный игровой слой (два спрайта).
- Облака и ночные огни Земли: процедурные игровые карты; ночные огни **не являются** снимками NASA Black Marble.

## Дополнительно устанавливаемые карты (install_official_textures.command)
**Credit: Solar System Scope — https://www.solarsystemscope.com/textures/**  
**License: Creative Commons Attribution 4.0 International (CC BY 4.0)**  
**License link: https://creativecommons.org/licenses/by/4.0/**

Русский текст для титров/меню игры:
«Карты планет: Solar System Scope (solarsystemscope.com), CC BY 4.0. Некоторые карты адаптированы для игры».

English credit:
"Planetary texture maps: Solar System Scope (solarsystemscope.com), CC BY 4.0; adapted for the game."

The original publisher says maps are based on NASA imagery and elevation data but include color adjustments and fictional fill for unmapped regions. Do not label these as exact NASA data.

### Import modifications
After running downloader: original JPGs renamed to `<planet>_surface.jpg` (no pixel edits); images may be further compressed on import by Godot. Planet shader applies dynamic shadows and rim atmosphere. Generated project shaders and UI are authored locally.

The supplied texture installer does not download a ring texture; the procedural ring sprites remain in use.
