@tool
extends Control
## v73: 20% larger life icon inset from divider; preserves icon-to-label gap.
## This Control is purely informational; it never captures gameplay gestures.

const ATLAS_PATH: String = "res://atlas/world_atlas.json"
const ROSTER_PATH: String = "res://planet_hub/data/representatives.json"
const CYAN: Color = Color("27dffe")
const AQUA: Color = Color("36f0e7")
const SKY_BLUE: Color = Color("80dfff")
const STATION_THUMBNAILS: Dictionary = {
    "st_mw": "res://assets/story/callisto_shipyard.png",
    "st_lmc": "res://assets/story/tarantula_lab_ship.png",
    "st_smc": "res://assets/story/living_archive_lotus.png",
    "st_ngc6822": "res://assets/story/titan_skull_ngc6822.png",
    "st_m31": "res://assets/story/inverted_pyramid_m31.png",
    "st_m33": "res://assets/story/last_gate_m33.png"
}
const SYSTEMS: Dictionary = {
    "mw": ["Млечный Путь", "Milky Way", "Voie lactée", "Milchstraße", "Vía Láctea", "Via Láctea"],
    "lmc": ["Большое Магелланово Облако", "Large Magellanic Cloud", "Grand Nuage de Magellan", "Große Magellansche Wolke", "Gran Nube de Magallanes", "Grande Nuvem de Magalhães"],
    "smc": ["Малое Магелланово Облако", "Small Magellanic Cloud", "Petit Nuage de Magellan", "Kleine Magellansche Wolke", "Pequeña Nube de Magallanes", "Pequena Nuvem de Magalhães"],
    "ngc6822": ["Галактика Барнарда", "Barnard's Galaxy", "Galaxie de Barnard", "Barnards Galaxie", "Galaxia de Barnard", "Galáxia de Barnard"],
    "m31": ["Андромеда", "Andromeda", "Andromède", "Andromeda", "Andrómeda", "Andrômeda"],
    "m33": ["Треугольник", "Triangulum", "Triangle", "Dreiecksgalaxie", "Triángulo", "Triângulo"]
}
const LOCALIZED: Dictionary = {
    "ru": ["Планета", "Станция", "Форма жизни:", "Система:", "Жизнь не обнаружена", "Люди", "Грибные организмы", "Фазовые существа", "Рептилии", "Магнитные существа", "Нейронные формы"],
    "en": ["Planet", "Station", "Life form:", "System:", "No life detected", "Humans", "Fungal organisms", "Phase beings", "Reptilians", "Magnetic beings", "Neural beings"],
    "fr": ["Planète", "Station", "Forme de vie :", "Système :", "Aucune vie détectée", "Humains", "Organismes fongiques", "Êtres de phase", "Reptiliens", "Êtres magnétiques", "Êtres neuronaux"],
    "de": ["Planet", "Station", "Lebensform:", "System:", "Kein Leben entdeckt", "Menschen", "Pilzorganismen", "Phasenwesen", "Reptilien", "Magnetische Wesen", "Neuronale Wesen"],
    "es": ["Planeta", "Estación", "Forma de vida:", "Sistema:", "Sin vida detectada", "Humanos", "Organismos fúngicos", "Seres de fase", "Reptilianos", "Seres magnéticos", "Seres neuronales"],
    "pt_BR": ["Planeta", "Estação", "Forma de vida:", "Sistema:", "Nenhuma vida detectada", "Humanos", "Organismos fúngicos", "Seres de fase", "Reptilianos", "Seres magnéticos", "Seres neurais"]
}
const RACE_INDEX: Dictionary = {"humans": 5, "mold": 6, "phase": 7, "reptiles": 8, "magnetic": 9, "neural": 10}
const LOCALE_INDEX: Dictionary = {"ru": 0, "en": 1, "fr": 2, "de": 3, "es": 4, "pt_BR": 5}
# Entries follow LOCALE_INDEX: ru, en, fr, de, es, pt_BR.
const STATION_NAMES: Dictionary = {
    "st_mw": ["Дальняя ремонтная верфь", "Outer Repair Shipyard", "Chantier de réparation", "Reparaturwerft", "Astillero de reparación", "Estaleiro de reparação"],
    "st_lmc": ["Лаборатория «Тарантул»", "Tarantula Laboratory", "Laboratoire Tarentule", "Tarantula-Labor", "Laboratorio Tarántula", "Laboratório Tarântula"],
    "st_smc": ["Живой архив", "Living Archive", "Archives vivantes", "Lebendiges Archiv", "Archivo viviente", "Arquivo Vivo"],
    "st_ngc6822": ["Голова Титана", "Titan's Head", "Tête du Titan", "Titanenkopf", "Cabeza del Titán", "Cabeça do Titã"],
    "st_m31": ["Перевёрнутая пирамида", "Inverted Pyramid", "Pyramide inversée", "Umgekehrte Pyramide", "Pirámide invertida", "Pirâmide invertida"],
    "st_m33": ["Последние врата", "Last Gate", "Dernière porte", "Letztes Tor", "Última puerta", "Último portal"]
}

var _id: String = ""
var _name: String = ""
var _meta: Dictionary = {}
var _system: Dictionary = {}
var _inhabited: bool = false
var _is_station: bool = false
var _race: String = ""
var _thumb: TextureRect
var _type_label: Label
var _name_label: Label
var _life_label: Label
var _life_value: Label
var _system_label: Label
var _system_value: Label
var _rim: StyleBoxFlat
var _inner: StyleBoxFlat

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _rim = StyleBoxFlat.new()
    _rim.bg_color = Color(0.005, 0.06, 0.14, 0.97)
    _rim.border_color = Color("1dd9ff")
    _rim.set_border_width_all(2)
    _rim.set_corner_radius_all(54)
    _rim.shadow_color = Color(0.0, 0.58, 1.0, 0.75)
    _rim.shadow_size = 9
    _rim.anti_aliasing = true
    _inner = StyleBoxFlat.new()
    _inner.bg_color = Color("06152f")
    _inner.set_corner_radius_all(50)
    _inner.anti_aliasing = true
    _thumb = TextureRect.new()
    _thumb.name = "AtlasPlanetOrStationThumbnail"
    _thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_thumb)
    _type_label = _label("ObjectType", Color.WHITE)
    _name_label = _label("ObjectName", AQUA)
    _life_label = _label("LifeType", Color.WHITE)
    _life_value = _label("LifeValue", AQUA)
    _system_label = _label("SystemType", Color.WHITE)
    _system_value = _label("SystemName", AQUA)
    resized.connect(_relayout)
    if not Engine.is_editor_hint():
        MobileLocale.language_changed.connect(_language_changed)
    _language_changed("ru" if Engine.is_editor_hint() else MobileLocale.language)

func _label(node_name: String, tint: Color) -> Label:
    var item := Label.new()
    item.name = node_name
    item.clip_text = true
    item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    item.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    item.mouse_filter = Control.MOUSE_FILTER_IGNORE
    item.add_theme_color_override("font_color", tint)
    item.add_theme_color_override("font_outline_color", Color("071225"))
    item.add_theme_constant_override("outline_size", 2)
    add_child(item)
    return item

func configure(world_id: String, displayed_name: String, metadata: Dictionary) -> void:
    _id = world_id
    _name = displayed_name
    _meta = metadata.duplicate(true)
    _is_station = bool(_meta.get("is_station", false))
    _inhabited = bool(_meta.get("inhabited", false))
    _system = {}
    var atlas_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ATLAS_PATH)) if FileAccess.file_exists(ATLAS_PATH) else {}
    if atlas_raw is Dictionary:
        for candidate in atlas_raw.get("systems", []):
            if candidate is Dictionary and str(candidate.get("id", "")) == str(_meta.get("system_id", "")):
                _system = candidate
                break
    _race = ""
    var roster_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROSTER_PATH)) if FileAccess.file_exists(ROSTER_PATH) else {}
    if roster_raw is Dictionary:
        var races: Dictionary = roster_raw.get("race_by_system", {})
        _race = str(races.get(str(_meta.get("system_id", "")), ""))
    var image_path: String = str(_meta.get("visual_asset", ""))
    if _is_station:
        image_path = str(STATION_THUMBNAILS.get(_id, image_path))
    elif image_path.is_empty():
        image_path = "res://assets/destinations/" + str(_meta.get("name_en", "")).to_lower() + ".png"
    _thumb.texture = null
    if not image_path.is_empty() and ResourceLoader.exists(image_path):
        _thumb.texture = load(image_path) as Texture2D
    _language_changed("ru" if Engine.is_editor_hint() else MobileLocale.language)
    queue_redraw()

func _language_changed(locale: String) -> void:
    if _type_label == null:
        return
    var language: String = locale if LOCALIZED.has(locale) else "en"
    var t: Array = LOCALIZED[language]
    _type_label.text = str(t[1] if _is_station else t[0]) + ":"
    var localized_name: String = str(_meta.get("name_ru", _name)) if language == "ru" else str(_meta.get("name_en", _name))
    if not _is_station and language != "ru" and language != "en" and _id.begins_with("mw_p"):
        # Existing six-language Solar System labels are already maintained in MobileLocale.
        var key: String = "planet_" + str(_meta.get("name_en", ""))
        var translation: String = MobileLocale.t(key)
        if translation != key:
            localized_name = translation
    if _is_station and STATION_NAMES.has(_id):
        var translated: Array = STATION_NAMES[_id]
        localized_name = str(translated[int(LOCALE_INDEX.get(language, 1))])
    _name_label.text = localized_name if not localized_name.is_empty() else _name
    _life_label.text = str(t[2])
    _life_value.text = str(t[int(RACE_INDEX.get(_race, 4))]) if _inhabited else str(t[4])
    _system_label.text = str(t[3])
    var system_id: String = str(_meta.get("system_id", ""))
    _system_value.text = str(SYSTEMS[system_id][int(LOCALE_INDEX.get(language, 1))]) if SYSTEMS.has(system_id) else str(_meta.get("system_name_ru", system_id))
    _relayout()

func _relayout() -> void:
    if _type_label == null or size.x < 120.0 or size.y < 28.0:
        return
    var w: float = size.x
    var h: float = size.y
    var pad: float = maxf(8.0, h * 0.13)
    var icon: float = h * 0.67
    var split_a: float = w * 0.345
    var split_b: float = w * 0.686
    # Image -> gap -> Planet/Station: Name on one single baseline.
    _thumb.position = Vector2(pad, (h - icon) * 0.5)
    _thumb.size = Vector2(icon, icon)
    _inline_pair(_type_label, _name_label, pad + icon + pad * 0.85, split_a - pad * 1.0, h)
    # Every separator has a protected icon slot. Text begins after the slot.
    # Keeping these independent prevents the icon from being masked by labels.
    _inline_pair(_life_label, _life_value, split_a + h * (1.12 + 0.0668), split_b - pad * 0.9, h)
    _inline_pair(_system_label, _system_value, split_b + h * 1.12, w - pad * 1.4, h)
    queue_redraw()

func _inline_pair(label: Label, value: Label, left: float, right: float, h: float) -> void:
    var available: float = maxf(10.0, right - left)
    var font: Font = ThemeDB.fallback_font
    var base_size: int = maxi(11, roundi(h * 0.265))
    var px: int = base_size
    var gap: float = maxf(3.0, h * 0.065)
    for unused in range(32):
        var lw: float = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x
        var vw: float = font.get_string_size(value.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x
        if lw + gap + vw <= available or px <= 9:
            break
        px -= 1
    var label_width: float = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x
    var value_width: float = font.get_string_size(value.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x
    # Labels use the FULL panel height. Vertical alignment must not be applied
    # a second time by offsetting the control downward.
    label.position = Vector2(left, 0.0)
    label.size = Vector2(minf(label_width + 2.0, available), h)
    label.add_theme_font_size_override("font_size", px)
    label.tooltip_text = label.text
    value.position = Vector2(left + label_width + gap, 0.0)
    value.size = Vector2(maxf(1.0, minf(value_width + 2.0, right - value.position.x)), h)
    value.add_theme_font_size_override("font_size", px)
    value.tooltip_text = value.text

func _draw() -> void:
    if size.x < 120.0 or size.y < 28.0:
        return
    var rect: Rect2 = Rect2(Vector2.ZERO, size)
    draw_style_box(_rim, rect)
    draw_style_box(_inner, rect.grow(-4.0))
    var split_a: float = size.x * 0.345
    var split_b: float = size.x * 0.686
    for x in [split_a, split_b]:
        draw_line(Vector2(x, size.y * 0.22), Vector2(x, size.y * 0.78), Color(0.2, 0.8, 1.0, 0.26), 5.0, true)
        draw_line(Vector2(x, size.y * 0.22), Vector2(x, size.y * 0.78), Color("60eaff"), 1.5, true)
    var h: float = size.y
    if _thumb.texture == null:
        if _is_station:
            _draw_station_symbol(Vector2(h * 0.5, h * 0.5), h * 0.28)
        else:
            _draw_fallback_planet(Vector2(h * 0.5, h * 0.5), h * 0.27)
    # v72: both vector icons fit wholly inside a dedicated, inset slot.
    # Do not draw at the control edge or behind the text hitbox.
    var icon_radius: float = h * 0.186
    _draw_life_icon(Vector2(split_a + h * (0.52 + 0.0668), h * 0.5), icon_radius)
    _draw_system_map(Vector2(split_b + h * 0.52, h * 0.5), icon_radius)

func _draw_fallback_planet(center: Vector2, radius: float) -> void:
    var palette: Array = _meta.get("palette", ["#5bc7e2"])
    var tint: Color = Color.html(str(palette[0])) if not palette.is_empty() else CYAN
    draw_circle(center + Vector2(1.5, 1.5), radius + 2.0, Color(0.0, 0.75, 1.0, 0.28))
    draw_circle(center, radius, tint)
    draw_arc(center, radius * 0.72, -1.2, 1.4, 24, Color(1.0, 1.0, 1.0, 0.24), 2.0, true)

func _draw_station_symbol(center: Vector2, radius: float) -> void:
    draw_arc(center, radius * 0.90, 0.0, TAU, 40, CYAN, 2.2, true)
    draw_circle(center, radius * 0.33, Color("c3e9fa"))
    draw_line(center + Vector2(0, -radius * 0.95), center + Vector2(0, radius * 0.95), CYAN, 2.3, true)
    draw_arc(center, radius * 0.62, 0.0, TAU, 40, Color("8edaf9"), 1.6, true)

func _draw_life_icon(center: Vector2, radius: float) -> void:
    var tint: Color = SKY_BLUE if _inhabited else Color("668da6")
    draw_circle(center, radius * 0.88, Color(0.04, 0.29, 0.45, 0.25))
    draw_arc(center, radius * 0.83, -2.4, 2.4, 40, Color(tint, 0.7), 1.4, true)
    if not _inhabited:
        draw_circle(center, radius * 0.39, Color(tint, 0.35))
        draw_line(center + Vector2(-radius * 0.4, radius * 0.4), center + Vector2(radius * 0.4, -radius * 0.4), tint, 3.0, true)
        return
    match _race:
        "mold":
            for off in [-0.40, 0.0, 0.40]:
                var c: Vector2 = center + Vector2(radius * float(off), radius * (0.08 + absf(float(off)) * 0.3))
                draw_line(c, c + Vector2(0, radius * 0.36), tint, 3.0, true)
                draw_arc(c, radius * (0.31 if off == 0.0 else 0.22), PI, TAU, 20, tint, 3.0, true)
        "phase":
            for a in [0.0, 2.1, 4.2]:
                draw_arc(center + Vector2.from_angle(float(a)) * radius * 0.18, radius * 0.40, 0.0, TAU, 32, tint, 1.8, true)
        "magnetic":
            draw_arc(center + Vector2(-radius * 0.20, 0), radius * 0.29, 0.0, TAU, 32, tint, 3.0, true)
            draw_arc(center + Vector2(radius * 0.20, 0), radius * 0.29, 0.0, TAU, 32, tint, 3.0, true)
            draw_line(center + Vector2(-radius * 0.06, -radius * 0.32), center + Vector2(radius * 0.06, radius * 0.32), Color.WHITE, 2.0, true)
        "neural":
            for a in [0.0, 1.05, 2.1, 3.15, 4.2, 5.25]:
                var tip: Vector2 = center + Vector2.from_angle(float(a)) * radius * 0.7
                draw_line(center, tip, tint, 2.0, true)
                draw_circle(tip, radius * 0.10, tint)
        _:
            # v72: entire human silhouette is inside the icon rim. The old
            # half-arc looked like a figure cropped at its lower 20 percent.
            draw_circle(center + Vector2(0.0, -radius * 0.27), radius * 0.22, tint)
            var bust: PackedVector2Array = PackedVector2Array([
                center + Vector2(-radius * 0.53, radius * 0.62),
                center + Vector2(-radius * 0.53, radius * 0.35),
                center + Vector2(-radius * 0.39, radius * 0.13),
                center + Vector2(-radius * 0.17, radius * 0.07),
                center + Vector2(radius * 0.17, radius * 0.07),
                center + Vector2(radius * 0.39, radius * 0.13),
                center + Vector2(radius * 0.53, radius * 0.35),
                center + Vector2(radius * 0.53, radius * 0.62)
            ])
            draw_colored_polygon(bust, tint)

func _draw_system_map(center: Vector2, radius: float) -> void:
    draw_circle(center, radius, Color("051f38"))
    draw_arc(center, radius, 0.0, TAU, 48, CYAN, 1.8, true)
    for r in [0.34, 0.56, 0.78]:
        draw_arc(center, radius * float(r), 0.0, TAU, 48, Color(0.18, 0.77, 0.99, 0.34), 0.9, true)
    draw_circle(center, radius * 0.11, Color("ffd080"))
    var planets: Array = _system.get("planets", [])
    for i in range(planets.size()):
        var planet: Dictionary = planets[i]
        var a: float = float(planet.get("phase", i * 0.78))
        var rad: float = radius * (0.31 + 0.48 * float(i + 1) / maxf(1.0, float(planets.size())))
        var location: Vector2 = center + Vector2.from_angle(a) * rad
        var focused: bool = str(planet.get("id", "")) == _id
        if focused:
            draw_circle(location, radius * 0.16, Color(0.0, 0.78, 1.0, 0.28))
        draw_circle(location, radius * (0.095 if focused else 0.057), Color("ffb969") if focused else Color("64ccef"))
    if _is_station:
        draw_circle(center + Vector2(radius * 0.72, -radius * 0.72), radius * 0.095, Color("ffca75"))
