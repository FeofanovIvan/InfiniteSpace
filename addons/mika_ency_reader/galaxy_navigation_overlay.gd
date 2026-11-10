extends "res://addons/mika_ency_reader/encyclopedia_ui.gd"
## MIKA Encyclopedia 5.7.2 -- additive navigation overlay.
## All visual style, backgrounds, scroll gestures and local changes stay
## in the existing encyclopedia_ui.gd. This script never replaces that file.

const GALAXY_IDS: Array[String] = ["mw", "lmc", "smc", "ngc6822", "m31", "m33", "crossroads"]
const CATEGORY_NAMES: Dictionary = {
    "ru": {"planets": "Планеты и галактики", "stations": "Космические станции", "races": "Формы жизни", "characters": "Персонажи", "science": "Наука и природа", "terms": "Технологии и термины"},
    "en": {"planets": "Planets & Galaxies", "stations": "Space Stations", "races": "Life Forms", "characters": "Characters", "science": "Science & Nature", "terms": "Technology & Terms"},
    "fr": {"planets": "Planètes et galaxies", "stations": "Stations spatiales", "races": "Formes de vie", "characters": "Personnages", "science": "Science et nature", "terms": "Technologie et termes"},
    "de": {"planets": "Planeten und Galaxien", "stations": "Raumstationen", "races": "Lebensformen", "characters": "Figuren", "science": "Wissenschaft und Natur", "terms": "Technologie und Begriffe"},
    "es": {"planets": "Planetas y galaxias", "stations": "Estaciones espaciales", "races": "Formas de vida", "characters": "Personajes", "science": "Ciencia y naturaleza", "terms": "Tecnología y términos"},
    "pt_BR": {"planets": "Planetas e galáxias", "stations": "Estações espaciais", "races": "Formas de vida", "characters": "Personagens", "science": "Ciência e natureza", "terms": "Tecnologia e termos"}
}
const GALAXY_UI: Dictionary = {
    "ru": {"choose": "Выбери галактику", "planets": "планет", "one": "мир", "special": "Особая область", "expand": "Открой список планет"},
    "en": {"choose": "Choose a galaxy", "planets": "planets", "one": "world", "special": "Special region", "expand": "Explore the planets"},
    "fr": {"choose": "Choisis une galaxie", "planets": "planètes", "one": "monde", "special": "Région spéciale", "expand": "Découvre les planètes"},
    "de": {"choose": "Wähle eine Galaxie", "planets": "Planeten", "one": "Welt", "special": "Besondere Region", "expand": "Planeten entdecken"},
    "es": {"choose": "Elige una galaxia", "planets": "planetas", "one": "mundo", "special": "Región especial", "expand": "Descubre los planetas"},
    "pt_BR": {"choose": "Escolha uma galáxia", "planets": "planetas", "one": "mundo", "special": "Região especial", "expand": "Explore os planetas"}
}
const RU_SYSTEM_NAMES: Dictionary = {
    "mw": "Млечный Путь",
    "lmc": "Большое Магелланово Облако",
    "smc": "Малое Магелланово Облако",
    "ngc6822": "Галактика Барнарда",
    "m31": "Андромеда",
    "m33": "Галактика Треугольника",
    "crossroads": "Перекрёсток миров"
}

var _expanded_galaxy: String = ""

func _section_title(section: String) -> String:
    var labels: Dictionary = CATEGORY_NAMES.get(_locale, CATEGORY_NAMES["ru"])
    return str(labels.get(section, _ui("category_" + section)))

func _galaxy_ui(key: String) -> String:
    var labels: Dictionary = GALAXY_UI.get(_locale, GALAXY_UI["ru"])
    return str(labels.get(key, key))

func _galaxy_name(galaxy_id: String) -> String:
    if _locale == "ru":
        return str(RU_SYSTEM_NAMES.get(galaxy_id, galaxy_id))
    return _ui("system_" + galaxy_id)

func _galaxy_entries(galaxy_id: String) -> Array:
    var result: Array = []
    for entry in _entries("planets"):
        if not (entry is Dictionary):
            continue
        var actual: String = "crossroads" if str(entry.get("id", "")) == "crossroads" else str(entry.get("system_id", ""))
        if actual == galaxy_id:
            result.append(entry)
    return result

func _show_page(reset_scroll: bool) -> void:
    if _mode != "galaxies":
        super._show_page(reset_scroll)
        return
    if not is_instance_valid(_cards):
        return
    _search_input.placeholder_text = _ui("search_default")
    _search_button.tooltip_text = _ui("search_default")
    _title.text = _section_title("planets")
    _subtitle.text = _galaxy_ui("choose")
    _render_cards()
    _layout()
    if reset_scroll:
        _scroll.set_deferred("scroll_vertical", 0)

func _render_cards() -> void:
    if _mode != "galaxies":
        super._render_cards()
        return
    _clear_cards()
    _render_galaxies()

func _galaxy_compact() -> bool:
    if has_method("_is_compact"):
        return bool(call("_is_compact"))
    return get_viewport_rect().size.x < 860.0

func _render_galaxies() -> void:
    var needle: String = _query.strip_edges().to_lower()
    var compact: bool = _galaxy_compact()
    for galaxy_id in GALAXY_IDS:
        var planets: Array = _galaxy_entries(galaxy_id)
        if planets.is_empty():
            continue
        var name_text: String = _galaxy_name(galaxy_id)
        var group_matches: bool = needle.is_empty() or name_text.to_lower().contains(needle)
        if not group_matches:
            for planet in planets:
                var searchable: String = _text_of("planets", planet, "title") + " " + _text_of("planets", planet, "description")
                if searchable.to_lower().contains(needle):
                    group_matches = true
                    break
        if not group_matches:
            continue
        var expanded: bool = _expanded_galaxy == galaxy_id
        var group_card: PanelContainer = _make_card(108 if compact else 126, "Galaxy_" + galaxy_id, "galaxy:" + galaxy_id)
        _cards.add_child(group_card)
        var group_row: HBoxContainer = _card_padding(group_card, 18 if compact else 24)
        var thumb: Texture2D = _planet_texture(str(planets[0].get("id", "")))
        if thumb == null and galaxy_id == "crossroads":
            thumb = _texture_if_exists("res://planet_hub/assets/v68_neon/crystal_reference.png")
        group_row.add_child(_icon(thumb, 72 if compact else 88, true))
        var subtitle: String = _galaxy_ui("special") if galaxy_id == "crossroads" else _galaxy_ui("expand")
        var count: String = str(planets.size()) + " " + (_galaxy_ui("one") if galaxy_id == "crossroads" else _galaxy_ui("planets"))
        _card_lines(group_row, name_text, subtitle, count)
        if expanded:
            for planet in planets:
                var item: Dictionary = planet
                var searchable: String = _text_of("planets", item, "title") + " " + _text_of("planets", item, "description")
                if not needle.is_empty() and not name_text.to_lower().contains(needle) and not searchable.to_lower().contains(needle):
                    continue
                var identifier: String = str(item.get("id", ""))
                var planet_card: PanelContainer = _make_card(92 if compact else 110, "Planet_" + identifier, "article:" + identifier)
                _cards.add_child(planet_card)
                var planet_row: HBoxContainer = _card_padding(planet_card, 28 if compact else 46)
                planet_row.add_child(_icon(_planet_texture(identifier), 60 if compact else 78, true))
                var secondary: String = _text_of("planets", item, "world_type")
                if secondary.is_empty():
                    secondary = name_text
                _card_lines(planet_row, _text_of("planets", item, "title"), secondary)
    if _cards.get_child_count() == 0:
        _render_empty()

func _on_search_changed(value: String) -> void:
    if _mode == "article" and _section == "planets":
        _query = value
        _mode = "galaxies"
        _show_page(true)
        return
    super._on_search_changed(value)

func _go_back() -> void:
    _drag_target = ""
    if _mode == "article" and _section == "planets":
        _mode = "galaxies"
        _show_page(true)
    elif _mode == "galaxies":
        _mode = "home"
        _expanded_galaxy = ""
        _query = ""
        _search_input.clear()
        _show_page(true)
    else:
        super._go_back()

func _navigate_to(route: String) -> void:
    if route.begins_with("galaxy:"):
        var now: int = Time.get_ticks_msec()
        if now - _last_open_ms < 220:
            return
        _last_open_ms = now
        var galaxy_id: String = route.trim_prefix("galaxy:")
        if not GALAXY_IDS.has(galaxy_id):
            return
        _expanded_galaxy = "" if _expanded_galaxy == galaxy_id else galaxy_id
        var saved_scroll: int = _scroll.scroll_vertical
        _show_page(false)
        _scroll.set_deferred("scroll_vertical", saved_scroll)
        return
    if route == "section:planets":
        var timestamp: int = Time.get_ticks_msec()
        if timestamp - _last_open_ms < 220:
            return
        _last_open_ms = timestamp
        _section = "planets"
        _article_id = ""
        _expanded_galaxy = ""
        _mode = "galaxies"
        _query = ""
        _search_input.clear()
        _search_visible = false
        _search_input.visible = false
        _show_page(true)
        return
    super._navigate_to(route)
