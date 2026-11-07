extends "res://addons/mika_ency_reader/galaxy_navigation_overlay.gd"
## MIKA Encyclopedia v5.7.3 -- exact travel-map galaxy art + visible article titles.
## Only presentation overrides: never edits encyclopedia_ui.gd, v5.7.2 logic,
## catalog data, settings, translations or scrolling/touch input handling.

const MAP_GALAXY_ART: Dictionary = {
    "mw": "res://assets/ui/galaxy_1.png",
    "lmc": "res://assets/ui/galaxy_2.png",
    "smc": "res://assets/ui/galaxy_3.png",
    "ngc6822": "res://assets/ui/galaxy_4.png",
    "m31": "res://assets/ui/galaxy_5.png",
    "m33": "res://assets/ui/galaxy_6.png",
    # The seventh map destination is a special world, not a seventh galaxy.
    "crossroads": "res://assets/atlas/suns/sun_6.png"
}

const ATLAS_NAME_FALLBACKS: Dictionary = {
    "ru": {
        "mw": "Млечный Путь",
        "lmc": "Большое Магелланово Облако",
        "smc": "Малое Магелланово Облако",
        "ngc6822": "Галактика Барнарда",
        "m31": "Андромеда",
        "m33": "Галактика Треугольника",
        "crossroads": "Перекрёсток миров"
    },
    "en": {
        "mw": "Milky Way",
        "lmc": "Large Magellanic Cloud",
        "smc": "Small Magellanic Cloud",
        "ngc6822": "Barnard's Galaxy",
        "m31": "Andromeda",
        "m33": "Triangulum Galaxy",
        "crossroads": "Crossroads of Worlds"
    }
}

func _galaxy_name(galaxy_id: String) -> String:
    # Prefer full names from the actual travel-map Atlas (Russian / English).
    # For the other four languages retain the encyclopedia translation if present.
    var names: Dictionary = ATLAS_NAME_FALLBACKS.get(_locale, {})
    if names.has(galaxy_id):
        return str(names[galaxy_id])
    var translated: String = _ui("system_" + galaxy_id).strip_edges()
    if not translated.is_empty() and translated != "system_" + galaxy_id:
        return translated
    return str(ATLAS_NAME_FALLBACKS["en"].get(galaxy_id, galaxy_id))

func _galaxy_texture_for(galaxy_id: String) -> Texture2D:
    # The SAME six atlas textures used by scripts/GalacticMap.gd, never a planet icon.
    return _texture_if_exists(str(MAP_GALAXY_ART.get(galaxy_id, "")))

func _card_lines(row: HBoxContainer, title_text: String, subtitle_text: String, count_text: String = "") -> void:
    # Shared fix: the original first line could collapse to zero height.
    # Station titles, galaxy names, and planet names all use this component.
    var compact: bool = _is_compact()
    var column: VBoxContainer = VBoxContainer.new()
    column.name = "MikaCardTextWithTitle"
    column.mouse_filter = Control.MOUSE_FILTER_IGNORE
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    column.alignment = BoxContainer.ALIGNMENT_CENTER
    column.add_theme_constant_override("separation", 4)
    row.add_child(column)

    var title_label: Label = _make_text(title_text, 23 if compact else 29, Color("#eafaff"))
    title_label.name = "VisibleCardTitle"
    title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    title_label.clip_text = false
    title_label.max_lines_visible = 2
    title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title_label.custom_minimum_size.y = 34.0 if compact else 42.0
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    column.add_child(title_label)

    if not subtitle_text.is_empty():
        var sub: Label = _make_text(subtitle_text, 15 if compact else 18, MUTED)
        sub.name = "CardSubtitle"
        sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        sub.max_lines_visible = 2
        sub.clip_text = false
        sub.custom_minimum_size.y = 21.0 if compact else 24.0
        column.add_child(sub)

    if not count_text.is_empty():
        var count: Label = _make_text(count_text, 13 if compact else 15, CYAN)
        count.name = "CardCount"
        count.custom_minimum_size.y = 18.0 if compact else 21.0
        column.add_child(count)

    var arrow: Label = _make_text("›", 32 if compact else 38, BRIGHT_CYAN)
    arrow.custom_minimum_size.x = 30.0 if compact else 40.0
    arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    row.add_child(arrow)

func _render_galaxies() -> void:
    var needle: String = _query.strip_edges().to_lower()
    var compact: bool = _is_compact()
    for galaxy_id in GALAXY_IDS:
        var planets: Array = _galaxy_entries(galaxy_id)
        if planets.is_empty():
            continue
        var galaxy_name: String = _galaxy_name(galaxy_id)
        var name_matches: bool = needle.is_empty() or galaxy_name.to_lower().contains(needle)
        var found: bool = name_matches
        if not found:
            for planet in planets:
                var hay: String = _text_of("planets", planet, "title") + " " + _text_of("planets", planet, "description")
                if hay.to_lower().contains(needle):
                    found = true
                    break
        if not found:
            continue

        var expanded: bool = _expanded_galaxy == galaxy_id
        var special: bool = galaxy_id == "crossroads"
        var galaxy_card: PanelContainer = _make_card(124 if compact else 140, "Galaxy_" + galaxy_id, "galaxy:" + galaxy_id)
        _cards.add_child(galaxy_card)
        var galaxy_row: HBoxContainer = _card_padding(galaxy_card, 22 if compact else 30)
        var picture: Texture2D = _galaxy_texture_for(galaxy_id)
        galaxy_row.add_child(_icon(picture, 82 if compact else 100, true))
        var count_line: String = _galaxy_ui("special") if special else str(planets.size()) + " " + _galaxy_ui("planets")
        _card_lines(galaxy_row, galaxy_name, count_line)

        if expanded:
            for planet in planets:
                var item: Dictionary = planet
                var hay: String = _text_of("planets", item, "title") + " " + _text_of("planets", item, "description")
                if not needle.is_empty() and not name_matches and not hay.to_lower().contains(needle):
                    continue
                var identifier: String = str(item.get("id", ""))
                var planet_card: PanelContainer = _make_card(100 if compact else 120, "Planet_" + identifier, "article:" + identifier)
                _cards.add_child(planet_card)
                var planet_row: HBoxContainer = _card_padding(planet_card, 30 if compact else 48)
                planet_row.add_child(_icon(_planet_texture(identifier), 68 if compact else 84, true))
                var secondary: String = _text_of("planets", item, "world_type")
                if secondary.is_empty():
                    secondary = galaxy_name
                _card_lines(planet_row, _text_of("planets", item, "title"), secondary)
    if _cards.get_child_count() == 0:
        _render_empty()
