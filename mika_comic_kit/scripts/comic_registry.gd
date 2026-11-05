extends RefCounted
## Shared immutable ID registry for game + PDF pipeline. Only the IDs determine appearance.
const BASE: String = "res://mika_comic_kit/"
static var _colors: Dictionary = {}
static var _fonts: Dictionary = {}
static var _catalog: Dictionary = {}

static func _read(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        push_error("MIKA Comic Kit missing: " + path)
        return {}
    var result: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if result is Dictionary:
        return result
    push_error("MIKA Comic Kit invalid JSON: " + path)
    return {}

static func tokens() -> Dictionary:
    if _colors.is_empty():
        var tokens_data: Dictionary = _read(BASE + "data/comic_tokens.json")
        _colors = tokens_data.get("colors", {})
        _fonts = tokens_data.get("fonts", {})
    return _colors

static func catalog() -> Dictionary:
    if _catalog.is_empty():
        _catalog = _read(BASE + "data/comic_element_catalog.json")
    return _catalog

static func color_id(id: String, fallback: Color = Color.WHITE) -> Color:
    var entry: Dictionary = tokens().get(id, {})
    if entry.has("hex"):
        return Color.html(str(entry["hex"]))
    return fallback

static func lettering(id: String) -> Dictionary:
    var entry: Dictionary = catalog().get("lettering", {}).get(id, {})
    if entry.is_empty():
        push_warning("Unknown lettering ID: " + id)
    return entry

static func panel(id: String) -> Dictionary:
    return catalog().get("panels", {}).get(id, {})

static func transition(id: String) -> Dictionary:
    return catalog().get("transitions", {}).get(id, {})

static func font_size(id: String) -> int:
    tokens()
    return int(_fonts.get(id, {}).get("base_px", 32))

static func font_resource(id: String) -> Font:
    var path: String = BASE + "fonts/" + id + ".ttf"
    if ResourceLoader.exists(path):
        return load(path) as Font
    return ThemeDB.fallback_font

static func all_ids(kind: String) -> Array[String]:
    var ids: Array[String] = []
    var entries: Dictionary = catalog().get(kind, {})
    for key in entries.keys():
        ids.append(str(key))
    ids.sort()
    return ids
